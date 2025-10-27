schema do
  input do
    integer :x
    integer :y
  end

  value :sum, input.x + input.y
  value :product, input.x * input.y

  trait :is_positive, input.x > 0
end
