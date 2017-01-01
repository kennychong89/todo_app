require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

def error_for_list_name(name)
  # add and return an array to store multiple errors
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

configure do
  enable :sessions
  set :sessions_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  erb :edit_list, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end
