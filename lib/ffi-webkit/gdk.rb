require "ffi"

module FFI
  module Gdk
    extend FFI::Library
    ffi_lib 'libgdk-x11-2.0'

    # Enter protected area
    attach_function :gdk_threads_init, [], :void

    # Leave protected area
    attach_function :gdk_threads_enter, [], :void

    attach_function :gdk_color_parse, [:string, :pointer], :void

    # Parse key name
    attach_function :gdk_keyval_from_name, [:string], :uint


    class Color < FFI::Struct
      layout(
        :pixel, :uint,
        :red,   :uint,
        :green, :uint,
        :blue,  :uint
      )
    end

    class EventKey < FFI::Struct
      layout(
        :type,             :int,
        :window,           :pointer,
        :send_event,       :int8,
        :time,             :uint32,
        :state,            :uint,
        :keyval,           :uint,
        :length,           :int,
        :string,           :string,
        :hardware_keycode, :uint16,
        :group,            :uint8,
        :is_modifier,      :int8
      )
    end

    Keys = enum(
      :return,    0xff0d,
      :escape,    0xff1b,
      :delete,    0xffff,
      :backspace, 0xff08,
      :tab,       0xff09,
      :colon,     0x10020a1
    )
  end
end