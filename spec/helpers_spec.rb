RSpec.describe(Helpers) do
  subject(:helper) { Class.new { include Helpers }.new }

  describe("#format_cost") do
    it("reports a nil cost as unknown") do
      expect(helper.format_cost(nil)).to(eq("Unknown cost"))
    end

    it("reports a zero cost as free") do
      expect(helper.format_cost(0)).to(eq("Free"))
      expect(helper.format_cost(0.0)).to(eq("Free"))
    end

    it("formats dollar-scale costs with two decimals") do
      expect(helper.format_cost(0.01)).to(eq("$0.01"))
      expect(helper.format_cost(0.129)).to(eq("$0.13"))
      expect(helper.format_cost(1.5)).to(eq("$1.50"))
      expect(helper.format_cost(1234.5)).to(eq("$1234.50"))
    end

    it("formats sub-cent costs with five decimals") do
      expect(helper.format_cost(0.00009)).to(eq("$0.00009"))
      expect(helper.format_cost(0.0034567)).to(eq("$0.00346"))
      expect(helper.format_cost(0.009999)).to(eq("$0.01000"))
    end

    it("floors costs too small to render into a distinct string") do
      # "$0.00000" would be indistinguishable from a genuinely free run
      expect(helper.format_cost(0.000001)).to(eq("< $0.00001"))
      expect(helper.format_cost(1e-9)).to(eq("< $0.00001"))
    end
  end
end
