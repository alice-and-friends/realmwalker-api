# frozen_string_literal: true

namespace :dev do
  desc 'Resets the development environments'
  task reset: :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['sidekiq:purge'].invoke
    ENV['globals'] = 'yes'
    ENV['geographies'] = '_Oslo'
    Rake::Task['db:seed'].invoke
    exec 'rails s'
  end
end
