using System;
using System.IO;
using System.Linq;
using WinAurex.Services;
using Xunit;

namespace WinAurex.Tests
{
    public class FileLoggerPathSafetyTests : IDisposable
    {
        private readonly string _root;
        private readonly string _parent;

        public FileLoggerPathSafetyTests()
        {
            _parent = Path.Combine(Path.GetTempPath(), "WinAurexLoggerTests");
            _root = Path.Combine(_parent, Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_root);
        }

        [Fact]
        public void TraversalAndRootedCategoriesStayUnderTheLogRoot()
        {
            var logger = new FileLogger(_root);

            logger.LogInfo("traversal", @"..\..\escape");
            logger.LogWarning("rooted", @"C:\Windows\Temp");
            logger.LogError("dots", null, "..");
            logger.LogAction("action-1", "ok", "details");

            var logFiles = Directory.GetFiles(_root, "*.log", SearchOption.AllDirectories);
            Assert.Equal(4, logFiles.Length);

            var rootWithSeparator = _root.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            Assert.All(logFiles, file => Assert.StartsWith(rootWithSeparator, file, StringComparison.OrdinalIgnoreCase));

            Assert.True(Directory.Exists(Path.Combine(_root, "escape")));
            Assert.True(Directory.Exists(Path.Combine(_root, "C__Windows_Temp")));
            Assert.True(Directory.Exists(Path.Combine(_root, "General")));
        }

        [Fact]
        public void EmptyOrInvalidCategoryFallsBackToGeneral()
        {
            var logger = new FileLogger(_root);

            logger.LogInfo("blank", "   ");
            logger.LogInfo("symbols", "///");

            var generalDirectory = Path.Combine(_root, "General");
            Assert.True(Directory.Exists(generalDirectory));

            var logFile = Assert.Single(Directory.GetFiles(generalDirectory, "*.log"));
            var contents = File.ReadAllText(logFile);
            Assert.Contains("blank", contents);
            Assert.Contains("symbols", contents);
        }

        [Fact]
        public void CategoryIsPreservedWhenItIsAlreadySafe()
        {
            var logger = new FileLogger(_root);

            logger.LogInfo("batch output", "Batch");

            var logFile = Assert.Single(Directory.GetFiles(Path.Combine(_root, "Batch"), "*.log"));
            Assert.Contains("batch output", File.ReadAllText(logFile));
        }

        public void Dispose()
        {
            try
            {
                if (Directory.Exists(_parent))
                {
                    Directory.Delete(_parent, recursive: true);
                }
            }
            catch
            {
                // Best-effort cleanup for temp files.
            }
        }
    }
}
