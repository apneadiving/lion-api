require 'spec_helper'

describe 'Tasks Requests' do
  describe 'GET /tasks' do
    it 'responds with a json containing the current list of tasks' do
      tasks = []
      2.times { tasks << current_user.tasks.create(title: 'lol') }
      get api_tasks_path

      last_response.status.should eq(200)
      parsed_response = JSON.parse(last_response.body)

      parsed_response['tasks'].should eq(
        tasks.map do |task|
          {
            'id' => task.id,
            'title' => task.title,
            'created_at' => task.created_at.iso8601(3),
            'client_id' => task.client_id,
            'completed' => false,
            'user_id' => task.user.id,
            'assignee_id' => task.assignee.try(:id)
          }
        end
      )

      parsed_response['users'].should eq(
        tasks.map do |task|
          {
            'id' => task.user.id,
            'avatar_url' => task.user.avatar_url,
            'nickname' => task.user.nickname,
            'points' => task.user.points
          }
        end.uniq
      )
    end
  end

  describe 'POST /tasks' do
    it 'creates a task and responds with the corresponding json' do
      task_params = { title: 'test', client_id: '1234' }
      post api_tasks_path, { task: task_params }.to_json

      last_response.status.should eq(201)

      JSON.parse(last_response.body)['task'].should include(
        {
          'title' => task_params[:title],
          'client_id' => task_params[:client_id]
        }
      )
    end
  end

  describe 'PATCH /tasks/{id}' do
    it 'updates a task and responds with the corresponding json' do
      task = Task.create(title: 'test')
      assignee = User.create(nickname: 'test')
      task_params = { title: 'omg', assignee_id: assignee.id }

      patch api_task_path(task), { task: task_params }.to_json

      last_response.status.should eq(200)

      JSON.parse(last_response.body)['task'].should include({
        'title' => task_params[:title],
        'assignee_id' => task_params[:assignee_id]
      })
    end
  end

  describe 'DESTROY /tasks/{id}' do
    it 'destroys a task and responds with no content' do
      task = Task.create(title: 'test')

      delete api_task_path(task)

      last_response.status.should eq(204)
      last_response.body.should eq('')
    end
  end
end