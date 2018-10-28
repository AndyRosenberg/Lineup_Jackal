Fabricator(:player) do
  full_name { Faker::Name.name }
  position { ['QB', 'RB', 'WR'].sample }
  status { "bench" }
  lineup { Fabricate(:lineup) }
  ff_id { Faker::Lorem.characters(4) }
end