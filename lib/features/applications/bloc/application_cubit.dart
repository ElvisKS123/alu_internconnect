import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ApplicationState extends Equatable {
  const ApplicationState();
  @override
  List<Object?> get props => [];
}

class ApplicationInitial extends ApplicationState {}
class ApplicationLoading extends ApplicationState {}

class ApplicationsLoaded extends ApplicationState {
  final List<ApplicationModel> applications;
  final String filter; // 'all' | 'pending' | 'under_review' | 'shortlisted' | 'accepted'

  const ApplicationsLoaded({
    required this.applications,
    this.filter = 'all',
  });

  List<ApplicationModel> get filtered {
    if (filter == 'all') return applications;
    return applications.where((a) => a.status == filter).toList();
  }

  @override
  List<Object?> get props => [applications, filter];
}

class ApplicationSubmitting extends ApplicationState {}

class ApplicationSubmitted extends ApplicationState {
  final ApplicationModel application;
  const ApplicationSubmitted(this.application);
  @override
  List<Object?> get props => [application];
}

class ApplicationError extends ApplicationState {
  final String message;
  const ApplicationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class ApplicationCubit extends Cubit<ApplicationState> {
  final ApplicationRepository _repository;
  StreamSubscription? _subscription;

  ApplicationCubit({required ApplicationRepository repository})
      : _repository = repository,
        super(ApplicationInitial());

  void loadStudentApplications(String studentId) {
    emit(ApplicationLoading());
    _subscription?.cancel();
    _subscription = _repository
        .watchStudentApplications(studentId)
        .listen(
          (apps) => emit(ApplicationsLoaded(applications: apps)),
          onError: (e) => emit(ApplicationError(e.toString())),
        );
  }

  void loadStartupApplications(String startupId, {String? opportunityId}) {
    emit(ApplicationLoading());
    _subscription?.cancel();
    _subscription = _repository
        .watchStartupApplications(startupId, opportunityId: opportunityId)
        .listen(
          (apps) => emit(ApplicationsLoaded(applications: apps)),
          onError: (e) => emit(ApplicationError(e.toString())),
        );
  }

  void setFilter(String filter) {
    if (state is ApplicationsLoaded) {
      final current = state as ApplicationsLoaded;
      emit(ApplicationsLoaded(
        applications: current.applications,
        filter: filter,
      ));
    }
  }

  Future<void> submitApplication({
    required String opportunityId,
    required String opportunityTitle,
    required String startupId,
    required String startupName,
    String? startupLogoUrl,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
    String? applicantPhotoUrl,
    required String coverLetter,
    String? portfolioUrl,
    List<String> relevantSkills = const [],
  }) async {
    emit(ApplicationSubmitting());
    try {
      final app = await _repository.submitApplication(
        opportunityId: opportunityId,
        opportunityTitle: opportunityTitle,
        startupId: startupId,
        startupName: startupName,
        startupLogoUrl: startupLogoUrl,
        applicantId: applicantId,
        applicantName: applicantName,
        applicantEmail: applicantEmail,
        applicantPhotoUrl: applicantPhotoUrl,
        coverLetter: coverLetter,
        portfolioUrl: portfolioUrl,
        relevantSkills: relevantSkills,
      );
      emit(ApplicationSubmitted(app));
    } on Exception catch (e) {
      emit(ApplicationError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateStatus({
    required String applicationId,
    required String status,
    String? note,
    DateTime? interviewDate,
  }) async {
    try {
      await _repository.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
        note: note,
        interviewDate: interviewDate,
      );
    } on Exception catch (e) {
      emit(ApplicationError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
