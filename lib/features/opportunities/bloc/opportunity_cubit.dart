import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/opportunity_model.dart';
import '../repositories/opportunity_repository.dart';

// ─── States ────

abstract class OpportunityState extends Equatable {
  const OpportunityState();
  @override
  List<Object?> get props => [];
}

class OpportunityInitial extends OpportunityState {}
class OpportunityLoading extends OpportunityState {}

class OpportunitiesLoaded extends OpportunityState {
  final List<OpportunityModel> opportunities;
  final List<OpportunityModel> recommended;
  final List<String> bookmarkedIds;
  final String? selectedCategory;
  final String? selectedType;
  final String? selectedLocation;
  final String searchQuery;

  const OpportunitiesLoaded({
    required this.opportunities,
    this.recommended = const [],
    this.bookmarkedIds = const [],
    this.selectedCategory,
    this.selectedType,
    this.selectedLocation,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        opportunities,
        recommended,
        bookmarkedIds,
        selectedCategory,
        selectedType,
        selectedLocation,
        searchQuery,
      ];

  OpportunitiesLoaded copyWith({
    List<OpportunityModel>? opportunities,
    List<OpportunityModel>? recommended,
    List<String>? bookmarkedIds,
    String? selectedCategory,
    String? selectedType,
    String? selectedLocation,
    String? searchQuery,
  }) {
    return OpportunitiesLoaded(
      opportunities: opportunities ?? this.opportunities,
      recommended: recommended ?? this.recommended,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      selectedCategory: selectedCategory,
      selectedType: selectedType,
      selectedLocation: selectedLocation,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class OpportunityError extends OpportunityState {
  final String message;
  const OpportunityError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───

class OpportunityCubit extends Cubit<OpportunityState> {
  final OpportunityRepository _repository;
  StreamSubscription? _opportunitiesSubscription;
  StreamSubscription? _bookmarksSubscription;
  String? _userId;
  List<String> _userSkills = [];

  
  List<OpportunityModel>? _cachedOpportunities;
  List<OpportunityModel> _cachedRecommended = [];
  List<String> _cachedBookmarks = [];
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedLocation;
  String _searchQuery = '';

  OpportunityCubit({required OpportunityRepository repository})
      : _repository = repository,
        super(OpportunityInitial());

  void init({required String userId, List<String> userSkills = const []}) {
    _userId = userId;
    _userSkills = userSkills;
    emit(OpportunityLoading());
    _startListening();
    _loadRecommended();
  }

  
  void _emitCurrent() {
    final opportunities = _cachedOpportunities;
    if (opportunities == null) return; 
    emit(OpportunitiesLoaded(
      opportunities: opportunities,
      recommended: _cachedRecommended,
      bookmarkedIds: _cachedBookmarks,
      selectedCategory: _selectedCategory,
      selectedType: _selectedType,
      selectedLocation: _selectedLocation,
      searchQuery: _searchQuery,
    ));
  }

  void _startListening({
    String? category,
    String? type,
    String? location,
    String? searchQuery,
  }) {
    _selectedCategory = category;
    _selectedType = type;
    _selectedLocation = location;
    _searchQuery = searchQuery ?? '';
    _cachedOpportunities = null;

    _opportunitiesSubscription?.cancel();
    _opportunitiesSubscription = _repository
        .watchOpenOpportunities(
          category: category,
          type: type,
          location: location,
          searchQuery: searchQuery,
        )
        .listen(
          (opportunities) {
            _cachedOpportunities = opportunities;
            _emitCurrent();
          },
          onError: (e) => emit(OpportunityError(e.toString())),
        );

    if (_userId != null) {
      _bookmarksSubscription?.cancel();
      _bookmarksSubscription = _repository
          .watchBookmarks(_userId!)
          .listen((bookmarks) {
        _cachedBookmarks = bookmarks;
        _emitCurrent();
      });
    }
  }

  Future<void> _loadRecommended() async {
    try {
      final recommended = await _repository.getRecommended(
        studentSkills: _userSkills,
      );
      _cachedRecommended = recommended;
      _emitCurrent();
    } catch (_) {}
  }

  void filterOpportunities({
    String? category,
    String? type,
    String? location,
    String? searchQuery,
  }) {
    _startListening(
      category: category,
      type: type,
      location: location,
      searchQuery: searchQuery,
    );
  }

  void clearFilters() => _startListening();

  Future<void> toggleBookmark(String opportunityId) async {
    if (_userId == null) return;
    final current = state is OpportunitiesLoaded
        ? (state as OpportunitiesLoaded)
        : null;
    final isBookmarked = current?.bookmarkedIds.contains(opportunityId) ?? false;
    await _repository.toggleBookmark(
      userId: _userId!,
      opportunityId: opportunityId,
      isBookmarked: isBookmarked,
    );
  }

  @override
  Future<void> close() {
    _opportunitiesSubscription?.cancel();
    _bookmarksSubscription?.cancel();
    return super.close();
  }
}
