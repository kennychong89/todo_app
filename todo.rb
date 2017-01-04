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

def error_for_todo_name(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

configure do
  enable :sessions
  set :sessions_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def check_todo(todo)
    "complete" if todo[:completed] 
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
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
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

post "/lists/:id" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updateed."
    redirect "/lists/#{@list_id}"
  end  
end

post "/lists/:id/delete" do
  id = params[:id].to_i

  if !session[:lists][id].nil?
    session[:lists].delete_at(id)
    session[:success] = "The list has been deleted."   
  else
    session[:error] = "Cannot find the list."
  end

  redirect "/lists" 
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  todo_name = params[:todo].strip
  error = error_for_todo_name(todo_name)
  @list = session[:lists][@list_id]

  if error
    session[:error] = error
  else
    @list[:todos] << {name: todo_name, completed: false}
    session[:success] = "Todo has been added to the list."
  end

  redirect "/lists/#{@list_id}"
end

post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  result = @list[:todos].delete_at(todo_id)
  
  if result.nil?
    session[:error] = "Unable to delete todo from list."
  else
    session[:success] = "The todo is deleted from list."
  end

  redirect "/lists/#{@list_id}"
end

post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  todo = @list[:todos][todo_id]
  is_completed = params[:completed] == "true"
  
  if todo.nil?
    session[:error] = "Cannot find todo in list."
  else
    todo[:completed] = is_completed
  end

  redirect "/lists/#{@list_id}"
end
