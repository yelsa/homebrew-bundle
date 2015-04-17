require "spec_helper"

describe Bundle::Commands::Cleanup do
  context "read Brewfile and currently installation" do
    before do
      allow(ARGV).to receive(:value).and_return(nil)
      allow(File).to receive(:read).and_return("tap 'x'\ntap 'y'\nbrew 'a'\nbrew 'b'")
      allow(Bundle::Commands::Cleanup).to receive(:`) do |arg|
        case arg
        when "brew list" then "a\nc\nd"
        when "brew tap" then "x\nz"
        end
      end
    end

    it "computes which formulae to uninstall" do
      expect(Bundle::Commands::Cleanup.formulae_to_uninstall).to eql(%w[c d])
      expect(Bundle::Commands::Cleanup.taps_to_untap).to eql(%w[z])
    end
  end

  context "no formulae to uninstall and no taps to untap" do
    before do
      allow(Bundle::Commands::Cleanup).to receive(:formulae_to_uninstall).and_return([])
      allow(Bundle::Commands::Cleanup).to receive(:taps_to_untap).and_return([])
      allow(ARGV).to receive(:dry_run?).and_return(false)
    end

    it "does nothing" do
      expect(Kernel).not_to receive(:system)
      Bundle::Commands::Cleanup.run
    end
  end

  context "there are formulae to uninstall" do
    before do
      allow(Bundle::Commands::Cleanup).to receive(:formulae_to_uninstall).and_return(%w[a b])
      allow(Bundle::Commands::Cleanup).to receive(:taps_to_untap).and_return([])
      allow(ARGV).to receive(:dry_run?).and_return(false)
    end

    it "uninstalls formulae" do
      expect(Kernel).to receive(:system).with(*%w[brew uninstall --force a b])
      expect { Bundle::Commands::Cleanup.run }.to output(/Uninstalled 2 formulae/).to_stdout
    end
  end

  context "there are taps to untap" do
    before do
      allow(Bundle::Commands::Cleanup).to receive(:formulae_to_uninstall).and_return([])
      allow(Bundle::Commands::Cleanup).to receive(:taps_to_untap).and_return(%w[a b])
      allow(ARGV).to receive(:dry_run?).and_return(false)
    end

    it "untaps taps" do
      expect(Kernel).to receive(:system).with(*%w[brew untap a b])
      Bundle::Commands::Cleanup.run
    end
  end

  context "there are formulae to uninstall and taps to untap but passing with `--dry-run`" do
    before do
      allow(Bundle::Commands::Cleanup).to receive(:formulae_to_uninstall).and_return(%w[a b])
      allow(Bundle::Commands::Cleanup).to receive(:taps_to_untap).and_return(%w[a b])
      allow(ARGV).to receive(:dry_run?).and_return(true)
    end

    it "lists formulae and taps" do
      expect(Bundle::Commands::Cleanup).to receive(:puts_columns).with(%w[a b]).twice
      expect(Kernel).not_to receive(:system)
      expect { Bundle::Commands::Cleanup.run }.to output(/Would uninstall:.*Would untap:/m).to_stdout
    end
  end
end
