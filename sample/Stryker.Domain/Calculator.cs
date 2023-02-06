using Stryker.Domain.Interfaces;

namespace Stryker.Domain
{
    public class Calculator : ICalculator
    {
        public double Divid(double value, double divisor)
        {
            return value / divisor;
        }

        public int Multiply(int value, int multiplier)
        {
            return value * multiplier;
        }

        public int Subtract(int value, int subtractValue)
        {
            return value - subtractValue;
        }

        public int Sum(int value1, int value2)
        {
            return value1 + value2;
        }
    }
}