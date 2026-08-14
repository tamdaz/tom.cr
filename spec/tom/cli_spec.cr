require "../spec_helper"

describe Tom::Font do
  it "renders a word with the right number of rows for each font" do
    Tom::Fonts::Wide.render("HI").split('\n').size.should eq(Tom::Fonts::Wide::HEIGHT)
    Tom::Fonts::Compact.render("HI").split('\n').size.should eq(Tom::Fonts::Compact::HEIGHT)
    Tom::Fonts::Mini.render("HI").split('\n').size.should eq(Tom::Fonts::Mini::HEIGHT)
  end

  it "renders spaces as blank columns" do
    with_space = Tom::Fonts::Wide.render("A B")
    without_space = Tom::Fonts::Wide.render("AB")
    with_space.should_not eq(without_space)
  end

  it "silently skips characters unsupported by the chosen font" do
    Tom::Fonts::Compact.render("A1B").should eq(Tom::Fonts::Compact.render("AB"))
  end

  it "is case-insensitive" do
    Tom::Fonts::Wide.render("hi").should eq(Tom::Fonts::Wide.render("HI"))
  end
end
