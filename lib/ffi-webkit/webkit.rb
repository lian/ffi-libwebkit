require "ffi"
require "ffi-webkit/gtk"

module FFI
  class Webkit < FFI::Gtk::Widget
    extend FFI::Library
    ffi_lib "libwebkitgtk-1.0"

    # Create webkit view
    attach_function :ffi_new, :webkit_web_view_new, [ ], :pointer
    # Load given uri in view
    attach_function :ffi_get_uri, :webkit_web_view_get_uri, [ :pointer ], :string
    # Set given uri in view
    attach_function :ffi_set_uri, :webkit_web_view_load_uri, [ :pointer, :string ], :void
    # Get title or uri loaded
    attach_function :ffi_get_title, :webkit_web_view_get_title, [ :pointer ], :string
    # Go back or forward in history
    attach_function :ffi_go_steps, :webkit_web_view_go_back_or_forward, [ :pointer, :int ], :void

    attr_accessor :uri

    def initialize
      @widget = self.ffi_new
    end

    def uri
      ffi_get_uri(@widget)
    end

    def uri=(uri)
      ffi_set_uri(@widget, uri)
    end

    def title
      ffi_get_title(@widget)
    end

    def back
      ffi_go_steps(@widget, -1)
    end

    def forward;
      ffi_go_steps(@widget, 1)
    end
  end
end