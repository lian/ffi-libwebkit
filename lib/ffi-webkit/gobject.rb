require "ffi"

module FFI
  module GThread
    extend FFI::Library
    ffi_lib "libgthread-2.0"
    attach_function :ffi_init, :g_thread_init, [ :pointer ], :void
  end

  module GObject
    extend FFI::Library
    ffi_lib "libgobject-2.0"

    callback :g_callback2, [ :pointer, :pointer ],                     :void
    callback :g_callback3, [ :pointer, :pointer, :pointer ],           :void
    callback :g_callback4, [ :pointer, :pointer, :pointer, :pointer ], :void

    # Add signal callback
    attach_function :ffi_signal_connect2, :g_signal_connect_data, [ :pointer, :string, :g_callback2, :pointer, :pointer, :int ], :ulong
    attach_function :ffi_signal_connect3, :g_signal_connect_data, [ :pointer, :string, :g_callback3, :pointer, :pointer, :int ], :ulong
    attach_function :ffi_signal_connect4, :g_signal_connect_data, [ :pointer, :string, :g_callback4, :pointer, :pointer, :int ], :ulong
  end
end