require "ffi"
require "ffi-webkit/gobject"
require "ffi-webkit/gdk"

module FFI
  module Gtk

    class Runner
      extend FFI::Library
      ffi_lib 'libgtk-x11-2.0'

      attach_function :gtk_init, [ :pointer, :pointer ], :void
      attach_function :gtk_main, [ ], :void
      attach_function :gtk_main_quit, [ ], :void
      attach_function :gtk_main, [ ], :void
      attach_function :gtk_main_iteration, [], :void
      attach_function :gtk_events_pending , [], :int
      attach_function :gtk_main_iteration_do, [:int], :int

      def initialize
        GThread.ffi_init(nil)
        gtk_init(nil,nil)
      end

      def step
        gtk_main_iteration if gtk_events_pending == 1
        gtk_events_pending
      end

      def step_loop
        loop{ sleep(0.2) if step == 0 }
      end

      def run
        gtk_main
      end
    end

    class Widget
      extend FFI::Library
      ffi_lib 'libgtk-x11-2.0'

      enum(:state,
      [
        :normal, 0,
        :active,
        :prelight,
        :selected,
        :insensitive
      ])

      # Set foreground color of widget
      attach_function :ffi_set_fg, :gtk_widget_modify_fg, [ :pointer, :state, :pointer ], :void
      # Set background color of widget
      attach_function :ffi_set_bg, :gtk_widget_modify_bg, [ :pointer, :state, :pointer ], :void
      # Set background color of widget
      attach_function :ffi_set_alignment, :gtk_misc_set_alignment, [ :pointer, :float, :float ], :void
      # Get title or uri loaded
      attach_function :ffi_set_can_focus, :gtk_widget_set_can_focus, [ :pointer, :bool ], :void
      # Get title or uri loaded
      attach_function :ffi_set_can_edit, :gtk_editable_set_editable, [ :pointer, :bool ], :void

      attr_accessor :widget

      def foreground=(color)
        col = FFI::Gdk::Color.new
        FFI::Gdk.gdk_color_parse(color, col.pointer)
        FFI::Gtk::Widget.ffi_set_fg(@widget, :normal, col.pointer)
      end

      def background=(color)
        col = FFI::Gdk::Color.new
        FFI::Gdk.gdk_color_parse(color, col.pointer)
        FFI::Gtk::Widget.ffi_set_bg(@widget, :normal, col.pointer)      
      end

      def connect(signal, callback, data)
        case callback.arity
          when 2 then
            FFI::GObject.ffi_signal_connect2(@widget, signal, callback, data, nil, 0)
          when 3 then
            FFI::GObject.ffi_signal_connect3(@widget, signal, callback, data, nil, 0)
          when 4 then
            FFI::GObject.ffi_signal_connect4(@widget, signal, callback, data, nil, 0)
        end
      end

      def alignment(xalign, yalign)
        ffi_set_alignment(@widget, xalign, yalign)
      end

      def focusable=(value)
        ffi_set_can_focus(@widget, value)
      end

      def editable=(value)
        ffi_set_can_edit(@widget, value)
      end

      def to_wid
        @widget
      end
    end

    class Container < Widget
      extend FFI::Library
      ffi_lib "libgtk-x11-2.0" 

      # Show all child widgets
      attach_function :ffi_show_all, :gtk_widget_show_all, [ :pointer ], :void
      # Add widget to container
      attach_function :ffi_add, :gtk_container_add, [ :pointer, :pointer ], :void

      def show_all
        ffi_show_all(@widget)
      end

      def add(widget)
        ffi_add(@widget, widget.to_wid)
      end
    end

    class Window < Container
      extend FFI::Library
      ffi_lib "libgtk-x11-2.0" 

      # Create window
      attach_function :ffi_new, :gtk_window_new, [ :int ], :pointer
      # Set window title
      attach_function :ffi_set_title, :gtk_window_set_title, [:pointer, :string], :void
      # Set window wmclass
      attach_function :ffi_set_klass, :gtk_window_set_wmclass, [:pointer, :string, :string], :void
      # Set default size of widget
      attach_function :ffi_set_size, :gtk_window_set_default_size, [ :pointer, :int, :int ], :void

      def initialize
        @widget = ffi_new(0)
      end

      def title=(str)
        ffi_set_title(@widget, str)
      end

      def klass=(klass)
        ffi_set_klass(@widget, klass[0], klass[1])
      end

      def size=(array)
        ffi_set_size(@widget, array[0], array[1])
      end
    end

    class Scrolled < Container
      extend FFI::Library
      ffi_lib "libgtk-x11-2.0"

      # Create scrolled window
      attach_function :ffi_new, :gtk_scrolled_window_new, [ :pointer, :pointer ], :pointer
      # Get vertical adjustment
      attach_function :ffi_get_vadjustment, :gtk_scrolled_window_get_vadjustment, [ :pointer ], :pointer

      def initialize
        @widget = ffi_new(nil, nil)
      end

      def vadjustment
        FFI::Gtk::Adjustment.new( vadjustment = ffi_get_vadjustment(@widget) )
      end
    end

    class Box < Widget
      extend FFI::Library
      ffi_lib "libgtk-x11-2.0"

      attach_function :ffi_vbox_new, :gtk_vbox_new, [ :bool, :int ], :pointer
      attach_function :ffi_hbox_new, :gtk_hbox_new, [ :bool, :int ], :pointer
      # Add widget to box
      attach_function :ffi_add, :gtk_box_pack_start, [:pointer, :pointer, :bool, :bool, :int], :void

      def initialize(type, homogenous, spacing)
        @widget = if(:vbox == type)
          ffi_vbox_new(homogenous, spacing)
        else
          ffi_hbox_new(homogenous, spacing)
        end
      end

      def add(widget, expand, fill, padding)
        ffi_add(@widget, widget.to_wid, expand, fill, padding)
      end
    end

    class Label < Widget
      extend FFI::Library
      ffi_lib "libgtk-x11-2.0"

      attach_function :ffi_new,           :gtk_label_new, [ :string ], :pointer
      attach_function :ffi_set_text,      :gtk_label_set_text, [ :pointer, :string ], :void
      attach_function :ffi_set_markup,    :gtk_label_set_markup, [ :pointer, :string ], :void
      attach_function :ffi_single_line,   :gtk_label_set_single_line_mode, [ :pointer, :bool ], :void
      attach_function :ffi_selectable,    :gtk_label_set_selectable , [ :pointer, :bool ], :void

      def initialize(single, selectable)
        @widget = ffi_new("Surf")
        ffi_single_line(@widget, single)
        ffi_selectable(@widget,  selectable)
      end

      def text=(str)
        ffi_set_text(@widget, str)
      end

      def markup=(str)
        ffi_set_markup(@widget, str)
      end
    end

    class Entry < Widget
      extend FFI::Library
      ffi_lib "libgtk-x11-2.0"

      attach_function :gtk_entry_new, [ ], :pointer
      attach_function :gtk_entry_set_has_frame, [ :pointer, :bool ], :void
      attach_function :gtk_entry_get_text, [ :pointer ], :string
      attach_function :gtk_entry_set_text, [ :pointer, :string ], :void
      attach_function :gtk_entry_get_text_length, [ :pointer ], :uint16
      attach_function :gtk_entry_append_text, [ :pointer, :string ], :void

      def initialize(frame)
        gtk_entry_set_has_frame(@widget = gtk_entry_new, frame)
      end

      def text
        gtk_entry_get_text(@widget)
      end

      def text=(str)
        gtk_entry_set_text(@widget, str)
      end

      def empty?
        0 < gtk_entry_get_length(@widget) ? false : true
      end

      def <<(str)
        gtk_entry_append_text(@widget, str)
      end
    end

    class Adjustment < FFI::Struct
      layout(
        :parent_instance, :pointer,
        :lower,           :double,
        :upper,           :double,
        :step_increment,  :double,
        :page_increment,  :double,
        :page_size,       :double
      )
    end
  end
end