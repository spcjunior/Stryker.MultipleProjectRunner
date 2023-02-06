using Microsoft.AspNetCore.Mvc;
using Moq;
using Stryker.Domain.Interfaces;
using Stryker.WebApi.Controllers;

namespace Stryker.WebApi.Test
{
    public class CalculatorTest
    {
        private readonly CalculatorController _controller;
        private readonly Mock<ICalculator> _mockService;


        public CalculatorTest()
        {
            _mockService = new Mock<ICalculator>();
            _controller = new CalculatorController(_mockService.Object);
        }

        [Theory]
        [InlineData(2, 3, 5)]
        [InlineData(-2, 3, 1)]
        [InlineData(0, 3, 3)]
        [Trait(nameof(ICalculator.Sum), "Success")]
        public void GetSum(int value1, int value2, int expected)
        {
            _mockService
                .Setup(a => a.Sum(value1, value2))
                .Returns(expected);

            var result = _controller.GetSum(value1, value2);

            var okObjectResult = Assert.IsType<OkObjectResult>(result);

            var valueResult = Assert.IsAssignableFrom<int>(okObjectResult.Value);

            Assert.Equal(expected, valueResult);
        }

        [Theory]
        [InlineData(2, 3, -1)]
        [InlineData(-2, 3, -5)]
        [InlineData(0, 3, -3)]
        [InlineData(5, 3, 2)]
        [Trait(nameof(ICalculator.Subtract), "Success")]
        public void GetSubtract(int value1, int subtractValue, int expected)
        {
            _mockService
                .Setup(a => a.Subtract(value1, subtractValue))
                .Returns(expected);

            var result = _controller.GetSubtract(value1, subtractValue);

            var okObjectResult = Assert.IsType<OkObjectResult>(result);

            var valueResult = Assert.IsAssignableFrom<int>(okObjectResult.Value);

            Assert.Equal(expected, valueResult);
        }

        [Theory]
        [InlineData(2, 3, 6)]
        [InlineData(-2, 3, -6)]
        [InlineData(0, 3, 0)]
        [InlineData(5, 3, 15)]
        [Trait(nameof(ICalculator.Multiply), "Success")]
        public void GetMultiply(int value1, int multiplier, int expected)
        {
            _mockService
                .Setup(a => a.Multiply(value1, multiplier))
                .Returns(expected);

            var result = _controller.GetMultiply(value1, multiplier);

            var okObjectResult = Assert.IsType<OkObjectResult>(result);

            var valueResult = Assert.IsAssignableFrom<int>(okObjectResult.Value);

            Assert.Equal(expected, valueResult);
        }

        [Theory]
        [InlineData(2, 3, 0.66666666666666663)]
        [InlineData(4, 2, 2)]
        [InlineData(7, 3, 2.3333333333333335)]
        [InlineData(15, 3, 5)]
        [Trait(nameof(ICalculator.Divid), "Success")]
        public void GetDivid_Success(double value1, double divisor, double expected)
        {
            _mockService
                .Setup(a => a.Divid(value1, divisor))
                .Returns(expected);

            var result = _controller.GetDivid(value1, divisor);

            var okObjectResult = Assert.IsType<OkObjectResult>(result);

            var valueResult = Assert.IsAssignableFrom<double>(okObjectResult.Value);

            Assert.Equal(expected, valueResult);
        }

        [Theory]
        [InlineData(2, 0)]
        [Trait(nameof(ICalculator.Divid), "Error")]
        public void GetDivid_Error(double value1, double divisor)
        {
            _mockService
                .Setup(a => a.Divid(value1, divisor))
                .Throws<DivideByZeroException>();

            var result = _controller.GetDivid(value1, divisor);

            var badRequestResult = Assert.IsType<BadRequestResult>(result);
        }
    }
}