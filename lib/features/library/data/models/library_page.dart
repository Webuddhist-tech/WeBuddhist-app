/// One page of a paged library list.
abstract interface class LibraryPage<T> {
  List<T> get items;
  bool get hasMore;
}
