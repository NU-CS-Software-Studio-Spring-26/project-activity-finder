namespace :db do
  namespace :seed do
    desc "Add 1000+ users and activities for development (run db:seed first). " \
         "Optional: SEED_LARGE_USERS, SEED_LARGE_ACTIVITIES, SEED_LARGE_SIGNUPS"
    task large: :environment do
      unless Rails.env.development? || Rails.env.test?
        abort "db:seed:large is intended for development/test only."
      end

      if User.count.zero?
        puts "No users found — running default db:seed first…"
        load Rails.root.join("db/seeds.rb")
      end

      require Rails.root.join("db/seeds/large")
      Seeds::Large.run
    end
  end
end
