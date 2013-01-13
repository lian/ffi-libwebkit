require "ffi"
require "ffi-webkit/webkit"

class FFI::Webkit

  class Browser < FFI::Gtk::Runner
    attr_accessor :mode, :win, :scrolled, :info, :status, :input, :vbox, :hbox, :webkit
    attr_accessor :keys, :keychain

    def initialize
      super

      # Init
      @mode     = :command
      @keys     = {}
      @keychain = ""

      # Create widgets
      @win      = FFI::Gtk::Window.new
      @scrolled = FFI::Gtk::Scrolled.new
      @info     = FFI::Gtk::Label.new(true, true)
      @status   = FFI::Gtk::Label.new(true, false)
      @input    = FFI::Gtk::Entry.new(false)
      @vbox     = FFI::Gtk::Box.new(:vbox, false, 0)
      @hbox     = FFI::Gtk::Box.new(:hbox, false, 5)
      @webkit   = FFI::Webkit.new

      # Options
      @win.size  = [ 800, 600 ]
      @win.title = "Surf"
      @win.klass = [ "Browser", "Surf" ]

      @win.background    = "#000000"
      @info.foreground   = "#ffffff"
      @status.foreground = "#ffffff"
      @input.foreground  = "#000000"
      @input.background  = "#ffffff"
      #@webkit.focusable  = false
      @webkit.focusable  = true
      @input.editable    = false
      @input.focusable   = false
      @info.alignment(0, 0)
      @status.alignment(1, 0)

      # Containers
      @win.add(@vbox)
      #@scrolled.add(@webkit)

      # Boxes
      #@vbox.add(@scrolled, true,  true, 0)
      @vbox.add(@webkit, true,  true, 0)
      #@vbox.add(@hbox,     false, true, 0)
      #@hbox.add(@info,     true,  true, 5)
      #@hbox.add(@status,   true,  true, 5)
      #@vbox.add(@input,    false, true, 0)

      # Signals
      @win.connect("destroy",                  method(:win_destroy).to_proc,     nil)
      @win.connect("key-press-event",          method(:win_keypress).to_proc,    nil)
      #@win.connect("visibility-notify-event",  method(:test_update_event).to_proc,    nil)
      #@win.connect("event",                    method(:test_update_event).to_proc,    nil)
      #@win.connect("client-event",             method(:test_update_event).to_proc,    nil)


      @webkit.connect("load-started",          method(:webkit_started).to_proc,  nil)
      @webkit.connect("load-finished",         method(:webkit_finished).to_proc, nil)
      @webkit.connect("load-progress-changed", method(:webkit_progress).to_proc, nil)
      @webkit.connect("title-changed",         method(:webkit_title).to_proc,    nil)
      @webkit.connect("scroll-event",          method(:webkit_scroll).to_proc,   nil)
      @webkit.connect("hovering-over-link",    method(:webkit_hover).to_proc,    nil)

      #@webkit.connect("status-bar-text-changed",    method(:test_update_event).to_proc,    nil)
      
      @win.show_all
    end

    def test_update_event(widget_p, event_p, gptr)
	    p "got test_udate_event!"
    end

    def uri=(uri)
      @webkit.uri = uri
      @info.text  = status(uri)
    end

    def add_keys(hash)
      hash.each{|v, k| keys[v.to_sym] = k }
    end

    def status(str)
      "%s" % [ str ]
    end

    def meter(progress, width = 10)
      times = (progress * width) / 100
      "[%s>%s]" % [ "=" * times, " " * (width - times) ]
    end

    def page()
    end
    
    private

    def commands(sym)
      case sym
        when :UriOpen then
          @input.text     = ":open "
          @input.editable = true
          @mode = :uri
        when :UriEdit then
          @input.text = ":open %s" % [ @webkit.uri ]
          @input.editable = true
          @mode = :uri
        when :ModeInsert then
          @mode             = :insert
          @webkit.focusable = true
          @input.text       = "-- INSERT --"
        when :ModeCommand then
          @mode             = :command
          @webkit.focusable = false
          @input.text       = ""
        when :BrowserBack then
          @webkit.back
        when :BrowserForward then
          @webkit.forward
        when :Quit then
          FFI::Gtk::Runner.ffi_quit 
      end
    end

    # Callbacks
    def win_destroy(widget, arg)
      FFI::Gtk::Runner.ffi_quit 
    end

    def win_keypress(widget, arg)
      event = FFI::Gdk::EventKey.new(arg)

      # Handle keys
      case event[:keyval]
        when FFI::Gdk::Keys[:escape]
          case @mode
            when :uri then
              @mode           = :command
              @input.editable = false
              @input.text     = ""
            when :command then
              @keychain = ""
              return
            when :insert then
              @mode             = :command
              @webkit.focusable = false
              @input.text       = ""
              @keychain         = ""
          end
        when FFI::Gdk::Keys[:return]
          case @mode
            when :uri then
              uri             = @input.text.gsub(":open ", "")
              uri             = "http://" + uri unless(uri.include?("http://"))
              @webkit.uri     = uri
              @info.text      = uri
              @input.editable = false
              @input.text     = ""
          end
        when FFI::Gdk::Keys[:backspace] then
          case @mode
            when :uri
             if(@input.text != ":open ")
              @input.text = @input.text.chop
            end
          end
        else
          case @mode
            when :uri then
              @input << event[:string]
            else
              @keychain << event[:string]

              if(@keys.include?(@keychain.to_sym))
                commands(@keys[@keychain.to_sym])
                @keychain = ""
              end
          end 
      end
         
      puts "Key: %s=%d, state=%d, modifier=%d" % [ 
        event[:string], event[:keyval], event[:state], event[:is_modifier]
      ]
    end

    def webkit_started(widget, arg)
      @status.text = meter(0)
    end

    def webkit_finished(widget, arg)
      @status.text = ""
    end

    def webkit_progress(widget, arg, data)
      @status.text = meter(arg.to_i)
    end

    def webkit_title(widget, arg1, arg2, data)
      title = arg2.read_string

      @win.title = "Surf: %s" % [ title ]
    end

    def webkit_scroll(widget, arg1, data)
      adjust = @scrolled.vadjustment

      puts "%f %f %f %f %f" % [ adjust[:lower], adjust[:upper], adjust[:step_increment],
        adjust[:page_increment], adjust[:page_size]]
    end

    def webkit_hover(widget, arg1, arg2, data)
      begin # Hover start
        uri        = arg2.read_string
        @info.text = status("Link: %s" % [ uri ])
      rescue # Hover end
        @info.text = status(@webkit.uri)
      end
    end
  end

end