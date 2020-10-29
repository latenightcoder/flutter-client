import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/task/task_selectors.dart';
import 'package:memoize/memoize.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';

List<InvoiceItemEntity> convertProjectToInvoiceItem(
    {BuildContext context, ProjectEntity project}) {
  final List<InvoiceItemEntity> items = [];
  final state = StoreProvider.of<AppState>(context).state;
  state.taskState.map.forEach((index, task) {
    if (task.isStopped && !task.isInvoiced && task.projectId == project.id) {
      final item = convertTaskToInvoiceItem(task: task, context: context);
      items.add(item);
    }
  });

  return items;
}

var memoizedDropdownProjectList = memo5(
    (BuiltMap<String, ProjectEntity> projectMap,
            BuiltList<String> projectList,
            BuiltMap<String, ClientEntity> clientMap,
            BuiltMap<String, UserEntity> userMap,
            String clientId) =>
        dropdownProjectsSelector(
            projectMap, projectList, clientMap, userMap, clientId));

List<String> dropdownProjectsSelector(
    BuiltMap<String, ProjectEntity> projectMap,
    BuiltList<String> projectList,
    BuiltMap<String, ClientEntity> clientMap,
    BuiltMap<String, UserEntity> userMap,
    String clientId) {
  final list = projectList.where((projectId) {
    final project = projectMap[projectId];
    if (clientId != null &&
        clientId.isNotEmpty &&
        project.clientId != clientId) {
      return false;
    }
    if (project.hasClient &&
        clientMap.containsKey(project.clientId) &&
        !clientMap[project.clientId].isActive) {
      return false;
    }
    return project.isActive;
  }).toList();

  list.sort((projectAId, projectBId) {
    final projectA = projectMap[projectAId];
    final projectB = projectMap[projectBId];
    return projectA.compareTo(
        projectB, ProjectFields.name, true, userMap, clientMap);
  });

  return list;
}

var memoizedFilteredProjectList = memo7((String filterEntityId,
        EntityType filterEntityType,
        BuiltMap<String, ProjectEntity> projectMap,
        BuiltList<String> projectList,
        ListUIState projectListState,
        BuiltMap<String, ClientEntity> clientMap,
        BuiltMap<String, UserEntity> userMap) =>
    filteredProjectsSelector(filterEntityId, filterEntityType, projectMap,
        projectList, projectListState, clientMap, userMap));

List<String> filteredProjectsSelector(
    String filterEntityId,
    EntityType filterEntityType,
    BuiltMap<String, ProjectEntity> projectMap,
    BuiltList<String> projectList,
    ListUIState projectListState,
    BuiltMap<String, ClientEntity> clientMap,
    BuiltMap<String, UserEntity> userMap) {
  final list = projectList.where((projectId) {
    final project = projectMap[projectId];
    final client =
        clientMap[project.clientId] ?? ClientEntity(id: project.clientId);
    final user = userMap[project.assignedUserId] ??
        UserEntity(id: project.assignedUserId);

    if (filterEntityId != null) {
      if (filterEntityType == EntityType.client &&
          !client.matchesEntityFilter(filterEntityType, filterEntityId)) {
        return false;
      } else if (filterEntityType == EntityType.user &&
          !user.matchesEntityFilter(filterEntityType, filterEntityId)) {
        return false;
      }
    } else if (!client.isActive) {
      return false;
    }

    if (!project.matchesFilter(projectListState.filter) &&
        !client.matchesFilter(projectListState.filter)) {
      return false;
    }

    if (!project.matchesStates(projectListState.stateFilters)) {
      return false;
    }

    if (projectListState.custom1Filters.isNotEmpty &&
        !projectListState.custom1Filters.contains(project.customValue1)) {
      return false;
    }

    if (projectListState.custom2Filters.isNotEmpty &&
        !projectListState.custom2Filters.contains(project.customValue2)) {
      return false;
    }
    /*
    if (projectListState.filterEntityId != null &&
        project.entityId != projectListState.filterEntityId) {
      return false;
    }
    */
    return true;
  }).toList();

  list.sort((projectAId, projectBId) {
    final projectA = projectMap[projectAId];
    final projectB = projectMap[projectBId];
    return projectA.compareTo(projectB, projectListState.sortField,
        projectListState.sortAscending, userMap, clientMap);
  });

  return list;
}

Duration taskDurationForProject(
  ProjectEntity project,
  BuiltMap<String, TaskEntity> taskMap,
) {
  int total = 0;
  taskMap.forEach((index, task) {
    if (task.isActive && task.projectId == project.id) {
      total += task.calculateDuration.inSeconds;
    }
  });
  return Duration(seconds: total);
}

var memoizedProjectStatsForClient = memo2(
    (String clientId, BuiltMap<String, ProjectEntity> projectMap) =>
        projectStatsForClient(clientId, projectMap));

EntityStats projectStatsForClient(
    String clientId, BuiltMap<String, ProjectEntity> projectMap) {
  int countActive = 0;
  int countArchived = 0;
  projectMap.forEach((projectId, project) {
    if (project.clientId == clientId) {
      if (project.isActive) {
        countActive++;
      } else if (project.isArchived) {
        countArchived++;
      }
    }
  });

  return EntityStats(countActive: countActive, countArchived: countArchived);
}

var memoizedProjectStatsForUser = memo2(
    (String userId, BuiltMap<String, ProjectEntity> projectMap) =>
        projectStatsForClient(userId, projectMap));

EntityStats projectStatsForUser(
    String userId, BuiltMap<String, ProjectEntity> projectMap) {
  int countActive = 0;
  int countArchived = 0;
  projectMap.forEach((projectId, project) {
    if (project.assignedUserId == userId) {
      if (project.isActive) {
        countActive++;
      } else if (project.isArchived) {
        countArchived++;
      }
    }
  });

  return EntityStats(countActive: countActive, countArchived: countArchived);
}

bool hasProjectChanges(
        ProjectEntity project, BuiltMap<String, ProjectEntity> projectMap) =>
    project.isNew ? project.isChanged : project != projectMap[project.id];
