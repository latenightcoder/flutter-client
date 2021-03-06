import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/models/task_model.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/task/task_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/presenters/entity_presenter.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';

class TaskPresenter extends EntityPresenter {
  static List<String> getDefaultTableFields(UserCompanyEntity userCompany) {
    return [
      TaskFields.client,
      TaskFields.project,
      TaskFields.description,
      TaskFields.duration,
      TaskFields.status,
      EntityFields.state,
    ];
  }

  static List<String> getAllTableFields(UserCompanyEntity userCompany) {
    return [
      ...getDefaultTableFields(userCompany),
      ...EntityPresenter.getBaseFields(),
      TaskFields.number,
      TaskFields.rate,
      TaskFields.calculatedRate,
      TaskFields.invoiceId,
      TaskFields.clientId,
      TaskFields.projectId,
      TaskFields.timeLog,
      TaskFields.isRunning,
      TaskFields.customValue1,
      TaskFields.customValue2,
      TaskFields.customValue3,
      TaskFields.customValue4,
      TaskFields.documents,
      TaskFields.updatedAt,
      TaskFields.archivedAt,
      TaskFields.isDeleted,
    ];
  }

  @override
  Widget getField({String field, BuildContext context}) {
    final task = entity as TaskEntity;
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;

    switch (field) {
      case TaskFields.client:
        return Text(state.clientState.map[task.clientId]?.displayName ?? '');
      case TaskFields.rate:
        return Text(formatNumber(task.rate, context));
      case TaskFields.calculatedRate:
        final rate = taskRateSelector(
          company: state.company,
          project: state.projectState.get(task.projectId),
          client: state.clientState.get(task.clientId),
          task: task,
        );
        return Text(formatNumber(rate, context));
      case TaskFields.project:
        return Text(state.projectState.map[task.projectId]?.name ?? '');
      case TaskFields.description:
        return Text(task.description);
      case TaskFields.duration:
        return Text('');
      case TaskFields.number:
        return Text(task.number.toString());
      case TaskFields.invoiceId:
        return Text(
            state.invoiceState.map[task.invoiceId]?.listDisplayName ?? '');
      case TaskFields.clientId:
        return Text(state.clientState.map[task.clientId]?.displayName ?? '');
      case TaskFields.projectId:
        return Text(
            state.projectState.map[task.projectId]?.listDisplayName ?? '');
      case TaskFields.timeLog:
        return Text(task.timeLog);
      case TaskFields.isRunning:
        return Text(task.isRunning.toString());
      case TaskFields.customValue1:
        return Text(task.customValue1);
      case TaskFields.customValue2:
        return Text(task.customValue2);
      case TaskFields.customValue3:
        return Text(task.customValue3);
      case TaskFields.customValue4:
        return Text(task.customValue4);
      case TaskFields.documents:
        return Text('${task.documents.length}');
      case TaskFields.updatedAt:
        return Text(
            formatDate(convertTimestampToDateString(task.updatedAt), context));
      case TaskFields.archivedAt:
        return Text(
            formatDate(convertTimestampToDateString(task.archivedAt), context));
      case TaskFields.isDeleted:
        return Text(task.isDeleted.toString());
      case TaskFields.status:
        return Text(state.taskStatusState.get(task.statusId).name);
    }

    return super.getField(field: field, context: context);
  }
}
