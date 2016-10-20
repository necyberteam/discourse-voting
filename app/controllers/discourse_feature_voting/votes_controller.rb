module DiscourseFeatureVoting
	class VotesController < ::ApplicationController
		requires_plugin 'discourse-feature-voting'

		def add
			user = User.find_by(id: params["user_id"])

			topic = Topic.find_by(id: params["topic_id"])

			topic.custom_fields["vote_count"] = topic.custom_fields["vote_count"].to_i + 1
			topic.save

			user.custom_fields["votes"] = user.votes.dup.push(params["topic_id"])
			user.save

			obj = {
				vote_limit: user.vote_limit, 
				super_vote_limit: user.super_vote_limit, 
				super_votes_remaining: user.super_votes_remaining,
				vote_count: topic.custom_fields["vote_count"].to_i,
				super_vote_count: topic.super_vote_count,
				who_voted: who_voted(topic),
				who_super_voted: who_super_voted(topic)
			}

			render json: obj
		end

		def remove
			topic = Topic.find_by(id: params["topic_id"])
			user = User.find_by(id: params["user_id"])

			if topic.custom_fields["vote_count"].to_i > 0
				topic.custom_fields["vote_count"] = topic.custom_fields["vote_count"].to_i - 1
			end
			topic.save

			user.custom_fields["votes"] = user.votes.dup - [params["topic_id"].to_s]
			user.custom_fields["super_votes"] = user.super_votes.dup - [params["topic_id"].to_s]
			user.save

			obj = {
				vote_limit: user.vote_limit, 
				super_vote_limit: user.super_vote_limit, 
				super_votes_remaining: user.super_votes_remaining,
				vote_count: topic.custom_fields["vote_count"].to_i,
				super_vote_count: topic.super_vote_count,
				who_voted: who_voted(topic),
				who_super_voted: who_super_voted(topic)
			}

			render json: obj
		end

		def upgrade
			topic = Topic.find_by(id: params["topic_id"])
			user = User.find_by(id: params["user_id"])

			user.custom_fields["super_votes"] = user.super_votes.dup.push(params["topic_id"])
			user.save

			obj = {
				vote_limit: user.vote_limit, 
				super_vote_limit: user.super_vote_limit, 
				super_votes_remaining: user.super_votes_remaining,
				vote_count: topic.custom_fields["vote_count"].to_i,
				super_vote_count: topic.super_vote_count,
				who_voted: who_voted(topic),
				who_super_voted: who_super_voted(topic)
			}
			
			render json: obj
		end

		def downgrade
			topic = Topic.find_by(id: params["topic_id"])
			user = User.find_by(id: params["user_id"])

			user.custom_fields["super_votes"] = user.super_votes.dup - [params["topic_id"].to_s]
			user.save

			obj = {
				vote_limit: user.vote_limit, 
				super_vote_limit: user.super_vote_limit, 
				super_votes_remaining: user.super_votes_remaining,
				vote_count: topic.custom_fields["vote_count"].to_i,
				super_vote_count: topic.super_vote_count,
				who_voted: who_voted(topic),
				who_super_voted: who_super_voted(topic)
			}

			render json: obj
		end

		def who_voted(topic)
			users = User.find(UserCustomField.where(name: "votes", value: topic.id).pluck(:user_id))
			ActiveModel::ArraySerializer.new(users, scope: Guardian.new(User.find_by(id: params["user_id"])), each_serializer: UserSerializer)
		end

		def who_super_voted(topic)
			users = User.find(UserCustomField.where(name: "super_votes", value: topic.id).pluck(:user_id))
			ActiveModel::ArraySerializer.new(users, scope: Guardian.new(User.find_by(id: params["user_id"])), each_serializer: UserSerializer)
		end
	end
end
