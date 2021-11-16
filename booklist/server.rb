# server.rb
require 'sinatra'
require "sinatra/namespace"
require 'mongoid'

# DB Setup
Mongoid.load! "mongoid.config"

# Models
class Book
  include Mongoid::Document

  field :title, type: String
  field :author, type: String
  field :isbn, type: String

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true

  index({ title: 'text' })
  index({ isbn:1 }, { unique: true, name: "isbn_index" })

  scope :title, -> (title) { where(title: /^#{title}/) }
  scope :isbn, -> (isbn) { where(isbn: isbn) }
  scope :author, -> (author) { where(author: author) }
end

# Serializers to normalize JSON output
class BookSerializer
  def initialize(book)
    @book = book
  end

  def as_json(*)
    data = {
      id:@book.id.to_s,
      title:@book.title,
      author:@book.author,
      isbn:@book.isbn
    }
    data[:errors] = @book.errors if@book.errors.any?
    data
  end
end

# Endpoints
get '/ ' do
  'Welcome to BookList!'
end

# Useful for versioning.
namespace '/api/v1' do

  before do
    content_type 'application/json'
  end

  get '/books' do  #=>  .../api/v1/books
    books = Book.all

      # Go through each defined scope and filter the books if a value was given for this specific scope.
      [:title, :isbn, :author].each do |filter|
        books = books.send(filter, params[filter]) if params[filter]
      end

    books.map { |book| BookSerializer.new(book) }.to_json  # Instead of books.to_json to normalize output.
  end

end