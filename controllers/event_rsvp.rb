class CalendarEvents::RsvpController < ApplicationController
  attr_accessor :topic
  before_action :check_user, only: [:add, :remove]
  before_action :find_topic
  before_action :check_if_enabled

  def add
    prop = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop) || []

    if @topic.event_going_max && list.length >= @topic.event_going_max
      raise I18n.t('event_rsvp.errors.going_max')
    end

    list.push(rsvp_params[:username]) if list.exclude?(rsvp_params[:username])

    @topic.custom_fields[prop] = list.join(',')

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  def remove
    prop = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop) || []

    list.delete(rsvp_params[:username])

    @topic.custom_fields[prop] = list.join(',')

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  def going
    users_going = @topic.event_going.map do |username|
      User.find_by(username: username) || nil
    end.compact

    serializer = ActiveModel::ArraySerializer.new(users_going, each_serializer: BasicUserSerializer)
    render_json_dump(serializer)
  end

  private

  def rsvp_params
    params.permit(:topic_id, :type, :username)
  end

  def check_user
    unless User.exists?(username: rsvp_params[:username])
      raise Discourse::InvalidAccess.new
    end
  end

  def find_topic
    if topic = Topic.find_by(id: rsvp_params[:topic_id])
      @topic = topic
    else
      raise Discourse::NotFound.new
    end
  end

  def check_if_enabled
    unless SiteSetting.events_rsvp && @topic.event_rsvp
      raise I18n.t('event_rsvp.errors.not_enabled')
    end
  end

  def push_update(topic, prop)
    channel = "/calendar-events/#{topic.id}"

    msg = {
      current_user_id: current_user.id,
      updated_at: Time.now,
      type: "rsvp"
    }

    msg[prop.to_sym] = topic.send(prop)

    MessageBus.publish(channel, msg)
  end
end
