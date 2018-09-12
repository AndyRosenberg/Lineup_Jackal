Fabricator(:user) do
  username { Faker::Name.first_name }
  password { Faker::Lorem.characters(7) }
  email { Faker::Internet.email }
end