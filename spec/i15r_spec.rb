require File.join(File.dirname(__FILE__), "..", "lib", "i15r")
require "spec"

$testing = true

describe "i15r" do

  before do
    @i15r = I15r.new
  end

  describe "converting file paths to message prefixes" do

    it "should correctly work from app root for views" do
      @i15r.file_path_to_message_prefix("app/views/users/new.html.erb").should == "users.new"
    end

    it "should correctly work from app root for helpers" do
      @i15r.file_path_to_message_prefix("app/helpers/users_helper.rb").should == "users_helper"
    end

    it "should correctly work from app root for controllers" do
      @i15r.file_path_to_message_prefix("app/controllers/users_controller.rb").should == "users_controller"
    end

    it "should correctly work from app root for models" do
      @i15r.file_path_to_message_prefix("app/models/user.rb").should == "user"
    end

    it "should correctly work from app root for deep dir. structures" do
      @i15r.file_path_to_message_prefix("app/views/member/session/users/new.html.erb").should == "member.session.users.new"
    end

    it "should raise if path does not contain any Rails app directories" do
      path = "projects/doodle.rb"
      lambda { @i15r.file_path_to_message_prefix(path) }.should raise_error(AppFolderNotFound)
    end

  end

  describe "turning plain messages into i18n message strings" do

    it "should downcase a single word" do
      @i15r.get_i18n_message_string("Name", "users.new").should == "users.new.name"
    end

    it "should replace spaces with underscores" do
      @i15r.get_i18n_message_string("New name", "users.index").should == "users.index.new_name"
    end

  end

  describe "message text replacement" do
    describe "tag contents" do
      it "should replace a single word" do
        plain = %(<label for="user-name">Name</label>)
        i18ned = %(<label for="user-name"><%= I18n.t("users.new.name") %></label>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should replace several words" do
        plain = %(<label for="user-name">Earlier names</label>)
        i18ned = %(<label for="user-name"><%= I18n.t("users.new.earlier_names") %></label>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should remove punctuation from plain strings" do
        plain = %(<label for="user-name">Got friends? A friend's name</label>)
        i18ned = %(<label for="user-name"><%= I18n.t("users.new.got_friends_a_friends_name") %></label>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should not remove punctuation outside plain strings" do
        plain = %(<label for="user-name">A friend's name:</label>)
        i18ned = %(<label for="user-name"><%= I18n.t("users.new.a_friends_name") %>:</label>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should preserve whitespace in the content part of the tag" do
        plain = %(<label for="user-name"> Name </label>)
        i18ned = %(<label for="user-name"> <%= I18n.t("users.new.name") %> </label>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

    end

    describe "tag attributes" do
      it "should replace a link's title" do
        plain = %(<a title="site root" href="/"><img src="site_logo.png" /></a>)
        i18ned = %(<a title="<%= I18n.t("users.new.site_root") %>" href="/"><img src="site_logo.png" /></a>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end
    end

    describe "rails helper params" do
      it "should replace a title in a link_to helper" do
        plain = %(<p class="highlighted"><%= link_to 'New user', new_user_path %></p>)
        i18ned = %(<p class="highlighted"><%= link_to I18n.t("users.index.new_user"), new_user_path %></p>)
        @i15r.internationalize(plain, "users.index").should == i18ned
      end

      it "should replace a title in a link_to helper with html attributes" do
        plain = %(<p><%= link_to "Create a new user", new_user_path, { :class => "add" } -%></p>)
        i18ned = %(<p><%= link_to I18n.t("users.index.create_a_new_user"), new_user_path, { :class => "add" } -%></p>)
        @i15r.internationalize(plain, "users.index").should == i18ned
      end

      it "should replace the title of a label helper in a form builder" do
        plain = %(<%= f.label :name, "Name" %>)
        i18ned = %(<%= f.label :name, I18n.t("users.new.name") %>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should replace the title of a label_tag helper" do
        plain = %(<%= label_tag :name, "Name" %>)
        i18ned = %(<%= label_tag :name, I18n.t("users.new.name") %>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should replace the title of a submit helper in a form builder" do
        plain = %(<%= f.submit "Create user" %>)
        i18ned = %(<%= f.submit I18n.t("users.new.create_user") %>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

      it "should replace the title of a submit_tag helper" do
        plain = %(<%= submit_tag "Create user" %>)
        i18ned = %(<%= submit_tag I18n.t("users.new.create_user") %>)
        @i15r.internationalize(plain, "users.new").should == i18ned
      end

    end

  end # "message text replacement"

  describe "rewriting files" do
    describe "when no prefix option was given" do
      it "should correctly internationalize messages using a prefix derived from the path" do
        message_prefix = "users.new"
        plain_snippet = <<-EOS
          <label for="user-name">Name</label>
          <input type="text" id="user-name" name="user[name]" />
        EOS
        i18ned_snippet = <<-EOS
          <label for="user-name"><%= I18n.t("#{message_prefix}.name") %></label>
          <input type="text" id="user-name" name="user[name]" />
        EOS
        @i15r.internationalize(plain_snippet, message_prefix).should == i18ned_snippet
      end
    end # "when no prefix option was given"

    describe "when an explicit prefix option was given" do
      it "should correctly internationalize messages using the prefix" do
        prefix_option = "mysite"
        plain_snippet = <<-EOS
          <label for="user-name">Name</label>
          <input type="text" id="user-name" name="user[name]" />
        EOS
        i18ned_snippet = <<-EOS
          <label for="user-name"><%= I18n.t("#{prefix_option}.name") %></label>
          <input type="text" id="user-name" name="user[name]" />
        EOS

        @i15r.internationalize(plain_snippet, prefix_option).should == i18ned_snippet
      end

    end # "when an explicit prefix option was given"

  end # rewriting files

end