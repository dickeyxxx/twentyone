class Habit < ActiveRecord::Base
  validates_presence_of :user_id, :what
  belongs_to :user
  has_many :habit_days, :order => :date
  before_destroy :delete_habit_days

  def to_s
    return self.what.sub(/\.$/, '')
  end

  def missed_days
    return ((Time.zone.now.to_date - self.start_date) - HabitDay.where('habit_id = ? AND date < ?', self.id, Time.zone.now.to_date).count).to_i
  end

  def days_completed
    return self.habit_days.count
  end

  def current_day
    return (Time.zone.now.to_date + 1 - self.start_date).to_i
  end

  def finished_dates
    finished_dates = []
    self.habit_days.each { |f| finished_dates << f.date }
    return finished_dates
  end

  def notification_time
    if self.next_notification
      return self.next_notification.strftime "%I:%M %p"
    else
      return nil
    end
  end

  def set_notification_hour(hour=8, tomorrow=false)
    if Time.zone.now.hour > hour or tomorrow
      d = DateTime.parse("#{ Time.zone.now.to_date + 1.day }T#{ hour }:00:00#{ Time.zone.formatted_offset(false) }")
    else
      d = DateTime.parse("#{ Time.zone.now.to_date }T#{ hour }:00:00#{ Time.zone.formatted_offset(false) }")
    end
    self.next_notification = Time.parse(d.to_s)
    self.save!
  end

  def start_date
    return self.habit_days.first ? self.habit_days.first.date : Time.zone.now.to_date
  end

  def send_notification
    logger.info "Sending notification to #{ self.user }"
    if self.user.phone_number and self.current_day <= 21
      self.set_notification_hour(self.next_notification.localtime.hour, true)
      TwilioHelper.send_sms(self.user.phone_number, "Day #{ self.current_day } of #{ self } missed #{ self.missed_days } days. To complete, reply DONE. To end these texts STOP.")
    else
      # user has no phone number, or has passed 21 days, delete the notification
      self.user.phone_number = nil
      self.user.save!
      self.next_notification = nil
      self.save!
    end
  end

  def delete_habit_days
    self.habit_days.each { |h| h.destroy }
  end

end
