require 'spec_helper'
require 'rom/memory'

describe 'Using in-memory repositories for cross-repo access' do
  let(:setup) do
    ROM.setup(left: :memory, right: :memory, main: :memory)
  end

  let(:repositories) { rom.repositories }
  let(:rom) { setup.finalize }

  it 'works' do
    setup.relation(:users, repository: :left) do
      def by_name(name)
        restrict(name: name)
      end
    end

    setup.relation(:tasks, repository: :right)

    setup.relation(:users_and_tasks, repository: :main) do
      def by_user(name)
        join(users.by_name(name), tasks)
      end
    end

    setup.mappers do
      define(:users_and_tasks) do
        group tasks: [:title]
      end
    end

    repositories[:left][:users] << { user_id: 1, name: 'Joe' }
    repositories[:left][:users] << { user_id: 2, name: 'Jane' }
    repositories[:right][:tasks] << { user_id: 1, title: 'Have fun' }
    repositories[:right][:tasks] << { user_id: 2, title: 'Have fun' }

    user_and_tasks = rom.relation(:users_and_tasks)
                     .by_user('Jane')
                     .as(:users_and_tasks)

    expect(user_and_tasks).to match_array([
      { user_id: 2, name: 'Jane', tasks: [{ title: 'Have fun' }] }
    ])
  end
end
