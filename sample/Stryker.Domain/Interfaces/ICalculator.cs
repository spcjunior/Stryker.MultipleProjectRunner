namespace Stryker.Domain.Interfaces
{
    public interface ICalculator
    {
        int Sum(int value1, int value2);
        int Subtract(int value, int subtractValue);
        double Divid(double value, double divisor);
        int Multiply(int value, int multiplier);
    }

}
