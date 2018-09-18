module ApplicationHelper
  # https://gist.github.com/suryart/7418454#gistcomment-970347
  def bootstrap_class_for(flash_type)
    {
      success: 'alert-success',
      error: 'alert-danger',
      alert: 'alert-warning',
      notice: 'alert-primary'
    }[flash_type.to_sym] || flash_type.to_s
  end

  def cloudcoin_value(serial_no)
  	value = 0
  	case serial_no
  	when 1..2097152 then value = 1
  	when 2097153..4194304 then value = 5
  	when 4194305..6291456 then value = 25
  	when 6291457..14680064 then value = 100
  	when 14680065..16777217 then value = 250
  	end
  	return value
  end
end
