Fabricator(:lineup) do
  name { Faker::Lorem.characters(10) }
  players { [] }
  league_type { "standard" }
  user { Fabricate(:user) }
end