class User < ActiveRecord::Base

	attr_accessor :remember_token

	before_save { self.email = self.email.downcase }
	validates :name, presence: true, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false}

	has_secure_password
	validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
           has_many :microposts, dependent: :destroy
           has_many :active_relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
           has_many :following, through: :active_relationships, source: :followed
           has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
           has_many :followers, through: :passive_relationships


	#Returns the hash digest of the given string
	def User.digest(string)
		cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                BCrypt::Engine.cost
    		BCrypt::Password.create(string, cost: cost)
    	end

    	#Returns a random token
    	def User.new_token
    		SecureRandom.urlsafe_base64
    	end

    	#Remembers the user in the database for use in persisten sessions
    	def remember
    		self.remember_token = User.new_token
    		update_attribute(:remember_digest, User.digest(remember_token))
    	end

    	#Returns true if the given token matches the digest
    	def authenticated?(remember_token)
    		return false if remember_digest.nil?
    		BCrypt::Password.new(remember_digest).is_password?(remember_token)
    	end

    	#Forgets a user
    	def forget
    		update_attribute(:remember_digest, nil)
    	end

           #Returns a user's status feed
           def feed
            following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
            Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", following_ids: following_ids, user_id: id)
           end

           #Follows a user
            def follow(other_user)
                active_relationships.create(followed_id: other_user.id)
            end

            #Unfollows a user
            def unfollow(other_user)
                active_relationships.find_by(followed_id: other_user.id).destroy
            end

            #Returns true if user is following another user
            def following?(other_user)
                following.include?(other_user)
            end

end
