using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using WinAurex.Contracts;
using WinAurex.Models;

namespace WinAurex.Services
{
    public class ActionService : IActionService
    {
        private readonly WinAurex.Contracts.Execution.IExecutionEngine _executionEngine;
        private readonly IStateService _stateService;
        private readonly ILogContract _logger;

        public ActionService(
            WinAurex.Contracts.Execution.IExecutionEngine executionEngine, 
            IStateService stateService,
            ILogContract logger)
        {
            _executionEngine = executionEngine ?? throw new ArgumentNullException(nameof(executionEngine));
            _stateService = stateService ?? throw new ArgumentNullException(nameof(stateService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public async Task<ActionExecutionResult> ApplyAsync(SystemAction action, CancellationToken cancellationToken = default)
        {
            if (action.ExecutionPlan == null)
            {
                return new ActionExecutionResult { ActionId = action.Id, Status = ActionStatus.Failed, Message = "No execution plan found." };
            }

            var context = new WinAurex.Contracts.Execution.PlanContext(
                Guid.NewGuid(),
                false,
                cancellationToken,
                System.Security.Principal.WindowsIdentity.GetCurrent().Name,
                new System.Security.Principal.WindowsPrincipal(System.Security.Principal.WindowsIdentity.GetCurrent()).IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator),
                System.Globalization.CultureInfo.CurrentCulture.Name,
                System.IO.Directory.GetCurrentDirectory(),
                _logger
            );

            var result = await _executionEngine.ExecutePlanAsync(action.ExecutionPlan, context);

            bool isSuccess = false;
            foreach (var evt in result.Events)
            {
                if (evt is WinAurex.Models.Execution.ExecutionCompletedEntry comp)
                {
                    isSuccess = comp.IsSuccess;
                }
            }

            if (isSuccess)
            {
                await _stateService.SetActionStateAsync(action, true);
                return new ActionExecutionResult { ActionId = action.Id, Status = ActionStatus.Applied };
            }

            return new ActionExecutionResult { ActionId = action.Id, Status = ActionStatus.Failed, Message = "Execution failed." };
        }

        public Task<ActionExecutionResult> PreviewAsync(SystemAction action, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        public async Task<ActionExecutionResult> RollbackAsync(SystemAction action, CancellationToken cancellationToken = default)
        {
            if (action.RollbackPlan == null)
            {
                // For now, we'll just set it to false in cache if there is no specific revert plan
                await _stateService.SetActionStateAsync(action, false);
                return new ActionExecutionResult { ActionId = action.Id, Status = ActionStatus.NotApplied };
            }

            var context = new WinAurex.Contracts.Execution.PlanContext(
                Guid.NewGuid(),
                false,
                cancellationToken,
                System.Security.Principal.WindowsIdentity.GetCurrent().Name,
                new System.Security.Principal.WindowsPrincipal(System.Security.Principal.WindowsIdentity.GetCurrent()).IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator),
                System.Globalization.CultureInfo.CurrentCulture.Name,
                System.IO.Directory.GetCurrentDirectory(),
                _logger
            );

            var result = await _executionEngine.ExecutePlanAsync(action.RollbackPlan, context);

            bool isSuccess = false;
            foreach (var evt in result.Events)
            {
                if (evt is WinAurex.Models.Execution.ExecutionCompletedEntry comp)
                {
                    isSuccess = comp.IsSuccess;
                }
            }

            if (isSuccess)
            {
                await _stateService.SetActionStateAsync(action, false);
                return new ActionExecutionResult { ActionId = action.Id, Status = ActionStatus.NotApplied };
            }

            return new ActionExecutionResult { ActionId = action.Id, Status = ActionStatus.Failed, Message = "Rollback failed." };
        }
    }
}
