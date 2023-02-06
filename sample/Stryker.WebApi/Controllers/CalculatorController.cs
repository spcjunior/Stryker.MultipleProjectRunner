using Microsoft.AspNetCore.Mvc;
using Stryker.Domain.Interfaces;

namespace Stryker.WebApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CalculatorController : ControllerBase
    {
        private readonly ICalculator _calculator;

        public CalculatorController(ICalculator calculator)
        {
            _calculator = calculator;
        }

        [HttpGet("sum")]
        public IActionResult GetSum(int value1, int value2)
        {
            var result = _calculator.Sum(value1, value2);

            return Ok(result);
        }

        [HttpGet("subtract")]
        public IActionResult GetSubtract(int value, int subtractValue)
        {
            var result = _calculator.Subtract(value, subtractValue);

            return Ok(result);
        }

        [HttpGet("divid")]
        public IActionResult GetDivid(double value, double divisor)
        {
            try
            {
                var result = _calculator.Divid(value, divisor);
                return Ok(result);
            }
            catch (DivideByZeroException)
            {
                return BadRequest();
            }
        }

        [HttpGet("multiply")]
        public IActionResult GetMultiply(int value, int multiplier)
        {
            var result = _calculator.Multiply(value, multiplier);

            return Ok(result);
        }
    }
}