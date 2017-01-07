require "sinatra"
require "sinatra/reloader" if development?
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

def error_for_todo_name(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

def load_list(id)
  list = session[:lists].find { |list| list[:id] == id }
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

def next_list_id(lists)
  max = lists.map { |list| list[:id] }.max || 0
  max + 1
end

configure do
  enable :sessions
  set :sessions_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

helpers do
  def todo_completed?(todo)
    "complete" if todo[:completed] 
  end

  def list_completed?(list)
    list[:todos].size > 0 && list[:todos].all? { |todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if list_completed?(list)
  end

  def todos_completed_to_total_todos(todos)
    todos_completed = todos.count { |todo| todo[:completed] }
    "#{todos_completed} / #{todos.count}"
  end

  def sort_list(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }
    incomplete_lists.each(&block)
    complete_lists.each(&block)    
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition{ |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
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
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :edit_list, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_list_id(session[:lists])
    session[:lists] << {id: id, name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@list_id}"
  end  
end

post "/lists/:id/delete" do
  id = params[:id].to_i

  session[:lists].reject! { |list| list[:id] == id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."   
    redirect "/lists" 
  end
end

post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  
  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}" 
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  todo_name = params[:todo].strip
  error = error_for_todo_name(todo_name)
  @list = load_list(@list_id)

  if error
    session[:error] = error
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << {id: id, name: todo_name, completed: false}
    session[:success] = "Todo has been added to the list."
  end

  redirect "/lists/#{@list_id}"
end

post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" # rack parses request info and passes to Sinatra
    status 204  
  else
    session[:success] = "The todo is deleted from list."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  is_completed = params[:completed] == "true"

  todo[:completed] = is_completed
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end