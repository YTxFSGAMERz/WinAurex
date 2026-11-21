using WinAurex.Models.Execution;
using Xunit;

namespace WinAurex.Tests
{
    public class ExecutionProgressTests
    {
        [Theory]
        [InlineData(0, 0, 0)]
        [InlineData(0, 3, 0)]
        [InlineData(1, 3, 33)]
        [InlineData(2, 3, 67)]
        [InlineData(3, 3, 100)]
        [InlineData(5, 3, 100)]
        [InlineData(101, 100, 100)]
        [InlineData(-1, 10, 0)]
        [InlineData(0, -5, 0)]
        [InlineData(2, -5, 0)]
        public void Percentage_StaysWithinDocumentedRange(int completed, int total, int expected)
        {
            var progress = new ExecutionProgress
            {
                CompletedOperations = completed,
                TotalOperations = total
            };

            Assert.Equal(expected, progress.Percentage);
        }
    }
}
