using Stryker.Domain.Interfaces;

namespace Stryker.Domain.Test
{
    public class CalculatorTest
    {
        private readonly ICalculator calculator;

        public CalculatorTest()
        {
            calculator = new Calculator();
        }

        [Theory]
        [InlineData(2, 3, 5)]
        [InlineData(-2, 3, 1)]
        [InlineData(0, 3, 3)]
        [Trait(nameof(ICalculator.Sum), "Success")]
        public void Sum(int value1, int value2, int expected)
        {
            var result = calculator.Sum(value1, value2);

            Assert.Equal(expected, result);
        }

        [Theory]
        [InlineData(2, 3, -1)]
        [InlineData(-2, 3, -5)]
        [InlineData(0, 3, -3)]
        [InlineData(5, 3, 2)]
        [Trait(nameof(ICalculator.Subtract), "Success")]
        public void Subtract(int value1, int subtractValue, int expected)
        {
            var result = calculator.Subtract(value1, subtractValue);

            Assert.Equal(expected, result);
        }

        [Theory]
        [InlineData(2, 3, 6)]
        [InlineData(-2, 3, -6)]
        [InlineData(0, 3, 0)]
        [InlineData(5, 3, 15)]
        [Trait(nameof(ICalculator.Multiply), "Success")]
        public void Multiply(int value1, int multiplier, int expected)
        {
            var result = calculator.Multiply(value1, multiplier);

            Assert.Equal(expected, result);
        }

        [Theory]
        [InlineData(2, 3, 0.66666666666666663)]
        [InlineData(4, 2, 2)]
        [InlineData(7, 3, 2.3333333333333335)]
        [InlineData(15, 3, 5)]
        [Trait(nameof(ICalculator.Divid), "Success")]
        public void Divid(double value1, double divisor, double expected)
        {
            var result = calculator.Divid(value1, divisor);

            Assert.Equal(expected, result);
        }
    }
}