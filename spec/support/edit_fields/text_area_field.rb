require_relative './edit_field'

class TextAreaField < EditField
  def input_selector
    'textarea'
  end

  def expect_save_button(enabled: true)
    if enabled
      expect(field_container).not_to have_selector("#{control_link}[disabled]")
    else
      expect(field_container).to have_selector("#{control_link}[disabled]")
    end
  end

  def save!
    submit_by_click
  end

  def submit_by_click
    target = field_container.find(control_link)
    scroll_to_element(target)
    target.click
  end

  def submit_by_keyboard
    input_element.native.send_keys :tab
  end

  def cancel_by_click
    target = field_container.find(control_link(:cancel))
    scroll_to_element(target)
    target.click
  end

  def field_type
    'textarea'
  end

  def control_link(action = :save)
    raise 'Invalid link' unless %i[save cancel].include?(action)

    ".inplace-edit--control--#{action}"
  end
end
