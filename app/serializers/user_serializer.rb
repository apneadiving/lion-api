class UserSerializer < ActiveModel::Serializer
  attributes :id, :avatar_url, :nickname, :points
end