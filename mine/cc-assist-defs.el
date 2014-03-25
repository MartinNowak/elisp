;;; cc-assist-defs.el --- Definitions for C++ STL/Boost Assistance.
;; TODO: (defgroup c++ify-assist)

(defconst c++-iostream-classes
  '(
    ("std::istream" [istream] "<istream>" (:doc "Input stream" :kind class))
    ("std::ostream" [ostream] "<ostream>" (:doc "Output stream" :kind class))
    ("std::iostream" [iostream] "<iostream>" (:doc "Input/Output stream" :kind class))

    ("std::ifstream" [ifstream] "<fstream>" (:doc "Input file stream class" :kind class))
    ("std::ofstream" [ofstream] "<fstream>" (:doc "Output file stream" :kind class))
    ("std::fstream" [fstream] "<fstream>" (:doc "Input/output file stream class" :kind class))

    ("std::istringstream" [istringstream] "<sstream>" (:doc "Input string stream class" :kind class))
    ("std::ostringstream" [ostringstream] "<sstream>" (:doc "Output string stream class" :kind class))
    ("std::stringstream" [stringstream] "<sstream>" (:doc "Input/output string stream class" :kind class))

    ("std::streambuf" [streambuf] "<streambuf>" (:doc "Base buffer class for streams" :kind class))
    ("std::filebuf" [filebuf] "<fstream>" (:doc "File stream buffer" :kind class))
    ("std::stringbuf" [stringbuf] "<sstream>" (:doc "String stream buffer" :kind class))

    ("std::fstream" [fstream] "<fstream>" (:doc "File stream" :kind class))
    ("std::ifstream" [ifstream] "<fstream>" (:doc "Input stream" :kind class))
    ("std::ofstream" [ofstream] "<fstream>" (:doc "Output stream" :kind class))
    )
  "C++ IOstream class templates."
  )

(defconst c++-stl-containers
  '(
    ("std::string" [string] "<string>" (:doc "String of char.") 'class-template)
    ("std::wstring" [wstring] "<wstring>" (:doc "String of wide char (wchar_t).") 'class-template)

    ("std::vector" [vector] "<vector>" (:doc "Vectors contain contiguous elements stored as an array. Accessing members of a vector or appending elements can be done in constant time, whereas locating a specific value or inserting elements into the vector takes linear time.") 'class-template)
    ("std::list" [list] "<list>" (:doc "Lists are sequences of elements stored in a linked list. Compared to vectors, they allow fast insertions and deletions, but random access takes linear time.") 'class-template)

    ("std::queue" [queue] "<queue>" (:doc "Queue is a container adapter that gives the programmer a FIFO (first-in, first-out) data structure.") 'class-template)
    ("std::dequeue" [dequeue] "<dequeue>" (:doc "Double-ended queues are like vectors, except that they allow fast insertions and deletions at the beginning (as well as the end) of the container.") 'class-template)
    ("std::priority_queue" [priority_queue] "<queue>" (:doc "Priority Queues are like queues, but the elements inside the queue are ordered by some predicate.") 'class-template)

    ("std::set" [set] "<set>" (:doc "Associative Container that contains a *sorted* set of *unique* objects.") 'class-template)
    ("std::multiset" [multiset] "<set>" (:doc "Associative Container that contains a *sorted* set of possibly *duplicate* objects.") 'class-template)

    ("std::unordered_set" [unordered_set] "<unordered_set>" (:doc "Associative Container that contains a *unsorted* set of *unique* objects." :std c++11) 'class-template)
    ("std::unordered_multiset" [unordered_multiset] "<unordered_set>" (:doc "Associative Container that contains a *unsorted* set of possibly *duplicate* objects." :std c++11) 'class-template)

    ("std::bitset" [bitset] "<bitset>" (:doc "Bitsets give the programmer a set of bits as a data structure. Bitsets can be manipulated by various binary operators such as logical AND, OR, and so on.") 'class-template)

    ("std::map" [map] "<map>" (:doc "Maps are associative containers that contain *sorted* unique key/value pairs. For example, you could create a map that associates a string with an integer, and then use that map to associate the number of days in each month with the name of each month.") 'class-template)
    ("std::multimap" [multimap] "<map>" (:doc "Multimaps are like maps, in that they are *sorted* associative containers, but differ from maps in that they allow duplicate keys.") 'class-template)

    ("std::unordered_map" [unordered_map] "<unordered_map>" (:doc "Hash-table-based *unsorted* associative containers that contain unique key/value pairs. For example, you could create a map that associates a string with an integer, and then use that map to associate the number of days in each month with the name of each month." :std c++11) 'class-template)
    ("std::unordered_multimap" [unordered_multimap] "<unordered_map>" (:doc "Unordered multimaps are like *unordered* maps, in that they are sorted associative containers, but differ from maps in that they allow duplicate keys." :std c++11) 'class-template)

    ("std::hash_map" [hash_map] "<hash_map>" (:doc "Like map but with hashing instead.")  'class-template)

    ("std::stack" [stack] "<stack>" (:doc "Container Adapter that gives the programmer the functionality of a stack -- specifically, a FILO (first-in, last-out) data structure.") 'class-template)

    ("std::auto_ptr" [auto_ptr] "<memory>" (:doc "The auto_ptr class allows the programmer to create pointers that point to other objects. When auto_ptr pointers are destroyed, the objects to which they point are also destroyed.") 'class-template)

    ("std::thread" [thread] "<thread>" (:doc "Portable thread class.") 'class-template)
    )
  "C++ STL Containers.")

(defconst c++-iostream-objects
  '(
    ("std::cin" [cin] "<iostream>" (:doc "Standard input stream.") 'object)
    ("std::cout" [cout] "<iostream>" (:doc "Standard output stream.") 'object)
    ("std::cerr" [cerr] "<iostream>" (:doc "Standard output stream for errors.") 'object)
    ("std::clog" [clog] "<iostream>" (:doc "Standard output stream for logging.") 'object)
    )
  "C++ IOstream Objects.")

(defconst c++-iostream-types
  '(
    ("fpos" [fpos] "<iostream>" (:doc "Stream position class template.") 'class-template)
    ("streamoff" [streamoff] "<iostream>" (:doc "Stream offset type.") 'type)
    ("streampos" [streampos] "<iostream>" (:doc "Stream position type.") 'type)
    ("streamsize" [streamsize] "<iostream>" (:doc "Stream size type.") 'types)
    )
  "C++ IOstream Types.")

(defconst c++-iostream-manipulators
  '(
    ("std::boolalpha" [boolalpha] "<iomanip>" (:doc "Alphanumerical bool values") 'manipulator-function)
    ("std::dec" [dec] "<iomanip>" (:doc "Use decimal base") 'manipulator-function)
    ("std::endl" [endl] "<iomanip>" (:doc "Insert newline and flush") 'manipulator-function)
    ("std::ends" [ends] "<iomanip>" (:doc "Insert null character") 'manipulator-function)
    ("std::fixed" [fixed] "<iomanip>" (:doc "Use fixed-point notation") 'manipulator-function)
    ("std::flush" [flush] "<iomanip>" (:doc "Flush stream buffer") 'manipulator-function)
    ("std::hex" [hex] "<iomanip>" (:doc "Use hexadecimal base") 'manipulator-function)
    ("std::internal" [internal] "<iomanip>" (:doc "Adjust field by inserting characters at an internal position") 'manipulator-function)
    ("std::left" [left] "<iomanip>" (:doc "Adjust output to the left") 'manipulator-function)
    ("std::noboolalpha" [noboolalpha] "<iomanip>" (:doc "No alphanumerical bool values") 'manipulator-function)
    ("std::noshowbase" [noshowbase] "<iomanip>" (:doc "Do not show numerical base prefixes") 'manipulator-function)
    ("std::noshowpoint" [noshowpoint] "<iomanip>" (:doc "Do not show decimal point") 'manipulator-function)
    ("std::noshowpos" [noshowpos] "<iomanip>" (:doc "Do not show positive signs") 'manipulator-function)
    ("std::noskipwsy" [noskipws] "<iomanip>" (:doc "Do not skip whitespaces") 'manipulator-function)
    ("std::nounitbuf" [nounitbuf] "<iomanip>" (:doc "Do not force flushes after insertions") 'manipulator-function)
    ("std::nouppercase" [nouppercase] "<iomanip>" (:doc "Do not generate upper case letters") 'manipulator-function)
    ("std::oct" [oct] "<iomanip>" (:doc "Use octal base") 'manipulator-function)
    ("std::resetiosflags" [resetiosflags] "<iomanip>" (:doc "Reset format flags") 'manipulator-function)
    ("std::right" [right] "<iomanip>" (:doc "Adjust output to the right") 'manipulator-function)
    ("std::scientific" [scientific] "<iomanip>" (:doc "Use scientific notation") 'manipulator-function)
    ("std::setbase" [setbase] "<iomanip>" (:doc "Set basefield flag") 'manipulator-function)
    ("std::setfill" [setfill] "<iomanip>" (:doc "Set fill character") 'manipulator-function)
    ("std::setiosflags" [setiosflags] "<iomanip>" (:doc "Set format flags") 'manipulator-function)
    ("std::setprecision" [setprecision] "<iomanip>" (:doc "Set decimal precision") 'manipulator-function)
    ("std::setw" [setw] "<iomanip>" (:doc "Set field width") 'manipulator-function)
    ("std::showbase" [showbase] "<iomanip>" (:doc "Show numerical base prefixes") 'manipulator-function)
    ("std::showpoint" [showpoint] "<iomanip>" (:doc "Show decimal point") 'manipulator-function)
    ("std::showpos" [showpos] "<iomanip>" (:doc "Show positive signs") 'manipulator-function)
    ("std::skipws" [skipws] "<iomanip>" (:doc "Skip whitespaces") 'manipulator-function)
    ("std::unitbuf" [unitbuf] "<iomanip>" (:doc "Flush buffer after insertions") 'manipulator-function)
    ("std::uppercase" [uppercase] "<iomanip>" (:doc "Generate upper-case letters") 'manipulator-function)
    ("std::ws" [ws] "<iomanip>" (:doc "Extract whitespaces") 'manipulator-function)
    )
  "C++ IOstream Manipulators.")

;; ((NAMESPACE FUNCTION), SYMBOL, INCLUDE-FILE BRIEF-DESCRIPTION &optional STANDARD ATTRIBUTE-LIST URL)
(defconst c++-stl-algorithms
  '(
    ;; Numeric operations

    ("std::count" [count] "<algorithm>" (:doc "Return the number of elements matching a given value"))
    ("std::count_if" [count_if] "<algorithm>" (:doc "Return the number of elements for which a predicate is true"))

    ("std::accumulate" [accumulate] "<numeric>" (:doc "Sum up a range of elements"))
    ("std::inner_product" [inner_product] "<numeric>" (:doc "Compute the inner product of two ranges of elements"))
    ("std::partial_sum" [partial_sum] "<numeric>" (:doc "Compute the partial sum of a range of elements"))

    ("std::iota" [iota] "<numeric>" (:doc "Fills the range [first, last) with sequentially increasing values, starting with value and repetitively evaluating ++value" :std c++11) nil "http://en.cppreference.com/w/cpp/algorithm/iota")
    ("std::adjacent_difference" [adjacent_difference] "<numeric>" (:doc "Compute the differences between adjacent elements in a range"))

    ("std::equal" [equal] "<algorithm>" (:doc "Determine if two sets of elements are the same"))

    ;; Non-modifying sequence operations

    ("std::all_of" [all_of] "<algorithm>" (:doc "Checks if unary predicate p returns true for all elements in the range [first, last)" :std c++11
                                                :sign (((InputIterator first) (InputIterator last) (UnaryPredicate p)))))
    ("std::any_of" [any_of] "<algorithm>" (:doc "Checks if unary predicate p returns true for at least one element in the range [first, last)" :std c++11
                                                :sign (((InputIterator first) (InputIterator last) (UnaryPredicate p)))))
    ("std::none_of" [none_of] "<algorithm>" (:doc "Checks if unary predicate p returns true for no elements in the range [first, last)" :std c++11
                                                  :sign (((InputIterator first) (InputIterator last) (UnaryPredicate p)))))

    ("std::adjacent_find" [adjacent_find] "<algorithm>" (:doc "Finds two items that are adjacent to eachother"))

    ("std::find" [find] "<algorithm>" (:doc "Find a value in a given range"))
    ("std::find_end" [find_end] "<algorithm>" (:doc "Find the last sequence of elements in a certain range"))
    ("std::find_first_of" [find_first_of] "<algorithm>" (:doc "Search for any one of a set of elements"))
    ("std::find_if" [find_if] "<algorithm>" (:doc "Find the first element for which a certain predicate is true"))
    ("std::find_if_not" [find_if_not] "<algorithm>" (:doc "Find the first element for which a certain predicate is *not* true" :std c++11))

    ("std::for_each" [for_each] "<algorithm>" (:doc "Apply a function to a range of elements"))

    ("std::search" [search] "<algorithm>" (:doc "Search for a range of elements"))
    ("std::search_n" [search_n] "<algorithm>" (:doc "Search for N consecutive copies of an element in some range"))

    ("std::mismatch" [mismatch] "<algorithm>" (:doc "Finds the first position where two ranges differ"))

    ;; Modifying sequence operations

    ("std::transform" [transform] "<algorithm>" (:doc "Applies a function to a range of elements"))

    ("std::swap" [swap] "<algorithm>" (:doc "Swap the values of two objects"))
    ("std::swap_ranges" [swap_ranges] "<algorithm>" (:doc "Swaps two ranges of elements"))

    ("std::copy" [copy] "<algorithm>" (:doc "Copy some range of elements to a new location"))
    ("std::copy_backward" [copy_backward] "<algorithm>" (:doc "Copy a range of elements in backwards order"))
    ("std::copy_n" [copy_n] "<algorithm>" (:doc "Copy N elements" :std c++11))
    ("std::copy_if" [copy_if] "<algorithm>" (:doc "Copy N elements conditionally" :std c++11))

    ("std::fill" [fill] "<algorithm>" (:doc "Assign a range of elements a certain value"))
    ("std::fill_n" [fill_n] "<algorithm>" (:doc "Assign a value to some number of elements"))

    ("std::move" [move] "<algorithm>" (:doc "Moves the elements from the range [first, last), to another range ending at d_last" :std c++11))
    ("std::move_backward" [move_backward] "<algorithm>" (:doc "Moves the elements from the range [first, last), to another range ending at d_last. The elements are moved in reverse order (the last element is moved first), but their relative order is preserved" :std c++11))

    ("std::generate" [generate] "<algorithm>" (:doc "Saves the result of a function in a range"))
    ("std::generate_n" [generate_n] "<algorithm>" (:doc "Saves the result of N applications of a function"))

    ("std::random_shuffle" [random_shuffle] "<algorithm>" (:doc "Randomly re-order elements in some range"))
    ("std::shuffle" [shuffle] "<algorithm>" (:doc "" :std c++11))

    ("std::iter_swap" [iter_swap] "<algorithm>" (:doc "Swaps the elements pointed to by two iterators"))

    ("std::remove" [remove] "<algorithm>" (:doc "Remove elements equal to certain value"))
    ("std::remove_copy" [remove_copy] "<algorithm>" (:doc "Copy a range of elements omitting those that match a certian value"))
    ("std::remove_copy_if" [remove_copy_if] "<algorithm>" (:doc "Create a copy of a range of elements, omitting any for which a predicate is true"))
    ("std::remove_if" [remove_if] "<algorithm>" (:doc "Remove all elements for which a predicate is true"))

    ("std::replace" [replace] "<algorithm>" (:doc "Replace every occurrence of some value in a range with another value"))
    ("std::replace_copy" [replace_copy] "<algorithm>" (:doc "Copy a range, replacing certain elements with new ones"))
    ("std::replace_copy_if" [replace_copy_if] "<algorithm>" (:doc "Copy a range of elements, replacing those for which a predicate is true"))
    ("std::replace_if" [replace_if] "<algorithm>" (:doc "Change the values of elements for which a predicate is true"))

    ("std::reverse" [reverse] "<algorithm>" (:doc "Reverse elements in some range"))
    ("std::reverse_copy" [reverse_copy] "<algorithm>" (:doc "Create a copy of a range that is reversed"))

    ("std::rotate" [rotate] "<algorithm>" (:doc "Move the elements in some range to the left by some amount"))
    ("std::rotate_copy" [rotate_copy] "<algorithm>" (:doc "Copy and rotate a range of elements"))

    ("std::unique" [unique] "<algorithm>" (:doc "Remove consecutive duplicate elements in a range")) ;Remove duplicates
    ("std::unique_copy" [unique_copy] "<algorithm>" (:doc "Create a copy of some range of elements that contains no consecutive duplicates"))

    ;; Partitioning operations

    ("std::partition" [partition] "<algorithm>" (:doc "Divide a range of elements into two groups"))
    ("std::is_partitioned" [is_partitioned] "<algorithm>" (:doc "" :std c++11))
    ("std::stable_partition" [stable_partition] "<algorithm>" (:doc "Divide elements into two groups while preserving their relative order"))
    ("std::partition_copy" [partition_copy] "<algorithm>" (:doc "" :std c++11))
    ("std::partition_point" [partition_point] "<algorithm>" (:doc "" :std c++11))

    ;; Sorting operations (on sorted ranges)
    ("std::sort" [sort] "<algorithm>" (:doc "Sort the range [\p first, \p last] into ascending order"
                                            :sign ((void
                                                    (RandomAccessIterator first) (RandomAccessIterator last)
                                                    &optional
                                                    (Compare comp))
                                                   )))
    ("std::stable_sort" [stable_sort] "<algorithm>" (:doc "Sort the range [\p first, \p last] of elements while preserving order between equal elements"
                                                          :sign ((void
                                                                  (RandomAccessIterator first) (RandomAccessIterator last)
                                                                  &optional
                                                                  (Compare comp))
                                                                 )))

    ;; Sort Predicates
    ("std::is_sorted" [is_sorted] "<algorithm>" (:doc "Returns true if a range is sorted in ascending order" :std c++11
                                                      :sign ((bool
                                                              (ForwardIterator first) (ForwardIterator last)
                                                              &optional
                                                              (StrictWeakOrdering comp))
                                                             )))
    ("std::is_sorted_until" [is_sorted_until] "<algorithm>" (:doc "Returns true if a range is sorted in ascending order up until a given value" :std c++11
                                                                  :sign ((ForwardIterator
                                                                          (ForwardIterator first) (ForwardIterator last)
                                                                          &optional
                                                                          (BinaryPredicate comp))
                                                                         )))

    ("std::partial_sort" [partial_sort] "<algorithm>" (:doc "Sort the first N elements of a range, where N = first-middle"
                                                            :sign ((void
                                                                    (RandomAccessIterator first) (RandomAccessIterator middle) (RandomAccessIterator last)
                                                                    &optional
                                                                    (Compare comp))
                                                                   )))
    ;; TODO: Use second-sel
    ("std::partial_sort_copy" [partial_sort_copy] "<algorithm>" (:doc "Copy and partially sort a range of elements"
                                                                      :sign ((RandomAccessIterator
                                                                              (InputIterator first) (InputIterator last)
                                                                              (RandomAccessIterator destination_first)
                                                                              (RandomAccessIterator destination_last)
                                                                              &optional
                                                                              Compare comp)
                                                                             )))

    ;; Binary search operations (on sorted ranges)

    ("std::binary_search" [binary_search] "<algorithm>" (:doc "Determine if an element exists in the certain range [\p first, \p last]"
                                                              :sign ((bool
                                                                      (ForwardIterator first) (ForwardIterator last)
                                                                      (const LessThanComparable& value)
                                                                      )
                                                                     (bool
                                                                      (ForwardIterator first) (ForwardIterator last)
                                                                      (const T& value)
                                                                      (StrictWeakOrdering comp))
                                                                     )))
    ("std::equal_range" [equal_range] "<algorithm>" (:doc "Search for a range of elements that are all equal to a certain element"))
    ("std::lower_bound" [lower_bound] "<algorithm>" (:doc "Search for the first place that a value can be inserted while preserving order"))
    ("std::upper_bound" [upper_bound] "<algorithm>" (:doc "Searches for the last possible location to insert an element into an ordered range"))

    ;; Minimum Maximum Operations

    ("std::lexicographical_compare" [lexicographical_compare] "<algorithm>" (:doc "Returns true if one range is lexicographically less than another"))
    ("std::lexicographical_compare_3way" [lexicographical_compare_3way] "<algorithm>" (:doc "Determines if one range is lexicographically less than or greater than another"))
    ("std::abs" [abs] "<algorithm>" (:doc "Returns the absolute value"))
    ("std::min" [min] "<algorithm>" (:doc "Returns the smaller of two elements"))
    ("std::max" [max] "<algorithm>" (:doc "Returns the larger of two elements"))
    ("std::minmax" [minmax] "<algorithm>" (:doc "Returns the smaller and larger of two elements" :std c++11))
    ("std::min_element" [min_element] "<algorithm>" (:doc "Returns the smallest element in a range"))
    ("std::max_element" [max_element] "<algorithm>" (:doc "Returns the largest element in a range"))
    ("std::minmax_element" [minmax_element] "<algorithm>" (:doc "Returns the smallest and largest element in a range" :std c++11))

    ;; Permutations

    ("std::is_permutation" [is_permutation] "<algorithm>" (:doc "Return true if arguments is a permutation" :std c++11))
    ("std::prev_permutation" [prev_permutation] "<algorithm>" (:doc "Generates the next smaller lexicographic permutation of a range of elements"))
    ("std::next_permutation" [next_permutation] "<algorithm>" (:doc "Generates the next greater lexicographic permutation of a range of elements"))

    ("std::nth_element" [nth_element] "<algorithm>" (:doc "Put one element in its sorted location and make sure that no elements to its left are greater than any elements to its right"))

    ;; Set operations (on sorted ranges)

    ("std::merge" [merge] "<algorithm>" (:doc "Merge two sorted ranges"))
    ("std::inplace_merge" [inplace_merge] "<algorithm>" (:doc "Merge two ordered ranges in-place"))
    ("std::includes" [includes] "<algorithm>" (:doc "Returns true if one set is a subset of another"))
    ("std::set_difference" [set_difference] "<algorithm>" (:doc "Computes the difference between two sets"))
    ("std::set_intersection" [set_intersection] "<algorithm>" (:doc "Computes the intersection of two sets"))
    ("std::set_symmetric_difference" [set_symmetric_difference] "<algorithm>" (:doc "Computes the symmetric difference between two sets"))
    ("std::set_union" [set_union] "<algorithm>" (:doc "Computes the union of two sets"))

    ;; Heap operations

    ("std::is_heap" [is_heap] "<algorithm>" (:doc "Returns true if a given range is a heap") nil (predicate))
    ("std::is_heap_until" [is_heap_until] "<algorithm>" (:doc "Returns true if a given range is a heap until a given value") nil (predicate))

    ("std::make_heap" [make_heap] "<algorithm>" (:doc "Creates a heap out of a range of elements") nil (generator))
    ("std::sort_heap" [sort_heap] "<algorithm>" (:doc "Turns a heap into a sorted range of elements"))

    ("std::pop_heap" [pop_heap] "<algorithm>" (:doc "Remove the largest element from a heap"))
    ("std::push_heap" [push_heap] "<algorithm>" (:doc "Add an element to a heap"))

    ;; Uncategorized

    ("std::random_sample" [random_sample] "<algorithm>" (:doc "Randomly copy elements from one range to another") SGI-extension)
    ("std::random_sample_n" [random_sample_n] "<algorithm>" (:doc "Sample N random elements from a range") SGI-extensions)

    )
  "C++ STL Algorithms (in `std' namespace).")

(defconst c++-gnu-extensions-algorithms
  '(
    ("__gnu_cxx::rope" [rope] "<ext/rope>" (:doc "Rope.") nil "https://en.wikipedia.org/wiki/Rope_%28computer_science%29")
    ("__gnu_cxx::versa_string" [rope] "<ext/vstring.h>" (:doc "Small-String-Optimized (SSO) Variant of std::string.") nil nil)
    )
  "C++ GNU Parallel STL Algorithms (in `__gnu_parallel' namespace).")

(defconst c++-gnu-parallel-algorithms
  '(
    ("__gnu_parallel::accumulate" [accumulate] "<parallel/numeric>" (:doc "Sum up a range of elements"))

    ("__gnu_parallel::adjacent_difference" [adjacent_difference] "<parallel/numeric>" (:doc "Compute the differences between adjacent elements in a range"))
    ("__gnu_parallel::adjacent_find" [adjacent_find] "<parallel/algorithm>" (:doc "Finds two items that are adjacent to eachother"))

    ("__gnu_parallel::count" [count] "<parallel/algorithm>" (:doc "Return the number of elements matching a given value"))
    ("__gnu_parallel::count_if" [count_if] "<parallel/algorithm>" (:doc "Return the number of elements for which a predicate is true"))

    ("__gnu_parallel::equal" [equal] "<parallel/algorithm>" (:doc "Determine if two sets of elements are the same"))

    ("__gnu_parallel::find" [find] "<parallel/algorithm>" (:doc "Find a value in a given range"))
    ("__gnu_parallel::find_first_of" [find_first_of] "<parallel/algorithm>" (:doc "Search for any one of a set of elements"))
    ("__gnu_parallel::find_if" [find_if] "<parallel/algorithm>" (:doc "Find the first element for which a certain predicate is true"))

    ("__gnu_parallel::for_each" [for_each] "<parallel/algorithm>" (:doc "Apply a function to a range of elements"))
    ("__gnu_parallel::generate" [generate] "<parallel/algorithm>" (:doc "Saves the result of a function in a range"))
    ("__gnu_parallel::generate_n" [generate_n] "<parallel/algorithm>" (:doc "Saves the result of N applications of a function"))

    ("__gnu_parallel::inner_product" [inner_product] "<parallel/numeric>" (:doc "Compute the inner product of two ranges of elements"))

    ("__gnu_parallel::lexicographical_compare" [lexicographical_compare] "<parallel/algorithm>" (:doc "Returns true if one range is lexicographically less than another"))

    ("__gnu_parallel::max_element" [max_element] "<parallel/algorithm>" (:doc "Returns the largest element in a range"))

    ("__gnu_parallel::merge" [merge] "<parallel/algorithm>" (:doc "Merge two sorted ranges"))

    ("__gnu_parallel::min_element" [min_element] "<parallel/algorithm>" (:doc "Returns the smallest element in a range"))
    ("__gnu_parallel::nth_element" [nth_element] "<parallel/algorithm>" (:doc "Put one element in its sorted location and make sure that no elements to its left are greater than any elements to its right"))

    ("__gnu_parallel::mismatch" [mismatch] "<parallel/algorithm>" (:doc "Finds the first position where two ranges differ"))

    ("__gnu_parallel::partial_sort" [partial_sort] "<parallel/algorithm>" (:doc "Sort the first N elements of a range"))
    ("__gnu_parallel::partial_sum" [partial_sum] "<parallel/numeric>" (:doc "Compute the partial sum of a range of elements"))

    ("__gnu_parallel::partition" [partition] "<parallel/algorithm>" (:doc "Divide a range of elements into two groups"))

    ("__gnu_parallel::random_shuffle" [random_shuffle] "<parallel/algorithm>" (:doc "Randomly re-order elements in some range"))

    ("__gnu_parallel::replace" [replace] "<parallel/algorithm>" (:doc "Replace every occurrence of some value in a range with another value"))
    ("__gnu_parallel::replace_if" [replace_if] "<parallel/algorithm>" (:doc "Change the values of elements for which a predicate is true"))

    ("__gnu_parallel::search" [search] "<parallel/algorithm>" (:doc "Search for a range of elements"))
    ("__gnu_parallel::search_n" [search_n] "<parallel/algorithm>" (:doc "Search for N consecutive copies of an element in some range"))

    ("__gnu_parallel::set_difference" [set_difference] "<parallel/algorithm>" (:doc "Computes the difference between two sets"))
    ("__gnu_parallel::set_intersection" [set_intersection] "<parallel/algorithm>" (:doc "Computes the intersection of two sets"))
    ("__gnu_parallel::set_symmetric_difference" [set_symmetric_difference] "<parallel/algorithm>" (:doc "Computes the symmetric difference between two sets"))
    ("__gnu_parallel::set_union" [set_union] "<parallel/algorithm>" (:doc "Computes the union of two sets"))

    ("__gnu_parallel::sort" [sort] "<parallel/algorithm>" (:doc "Sort a range into ascending order"))

    ("__gnu_parallel::stable_sort" [stable_sort] "<parallel/algorithm>" (:doc "Sort a range of elements while preserving order between equal elements"))

    ("__gnu_parallel::transform" [transform] "<parallel/algorithm>" (:doc "Applies a function to a range of elements")) ;Alias: map

    ("__gnu_parallel::unique_copy" [unique_copy] "<parallel/algorithm>" (:doc "Create a copy of some range of elements that contains no consecutive duplicates"))
    )
  "C++ GNU Parallel STL Algorithms (in `__gnu_parallel'
namespace). For details see
http://gcc.gnu.org/onlinedocs/libstdc++/manual/bk01pt03ch18s03.html#parallel_mode.using.parallel_mode")

(defconst c++-boost-basic-containers
  '(
    ("boost::any" [any] "<boost/any.hpp>" (:doc "Safe, generic container for single values of different value types.") 'class-template)
    ("boost::array" [array] "<boost/array.hpp>" (:doc "STL compliant container wrapper for arrays of constant size.") 'class-template)
    ("boost::bimap" [bimap] "<boost/bimap.hpp>" (:doc "Bidirectional maps.") 'class-template)
    ("boost::circular_buffer" [circular_buffer] "<boost/circular_buffer.hpp>" (:doc "STL compliant container also known as ring or cyclic buffer.") 'class-template)
    ("boost::compressed_pair" [compressed_pair] "<boost/compressed_pair.hpp>" (:doc "Empty member optimization.") 'class-template)
    ("boost::dynamic_bitset" [dynamic_bitset] "<boost/dynamic_bitset.hpp>" (:doc "A runtime sized version of std::bitset.") 'class-template)
    ("boost::fusion" [fusion] "<boost/fusion.hpp>" (:doc "Library for working with tuples, including various containers, algorithms.") 'class-template)
    ("boost::gil" [gil] "<boost/gil/...>" (:doc "Generic Image Library.") 'class-template)
    ("boost::graph" [graph] "<boost/graph/...>" (:doc "Generic graph components and algorithms.") 'class-template)
    ("boost::intrusive" [intrusive] "<boost/intrusive/...>" (:doc "Intrusive containers and algorithms") 'class-template)
    ("boost::multi_array" [multi_array] "<boost/multi_array.hpp>" (:doc "Multidimensional containers and adaptors for arrays of contiguous data.") 'class-template)
    ("boost::multi_index" [multi_index] "<boost/multi_index.hpp>" (:doc "Containers with multiple STL-compatible access interfaces.") 'class-template)
    ("boost::multi_index_container" [multi_index_container] "<boost/multi_index_container.hpp>" (:doc "Containers with multiple STL-compatible access interfaces.") 'class-template)
    ("boost::pointer" [pointer] "<boost/pointer.hpp>" (:doc "Containers for storing heap-allocated polymorphic objects to ease OO-programming.") 'class-template)
    ("boost::property" [property] "<boost/property.hpp>" (:doc "Concepts defining interfaces which map key objects to value objects.") 'class-template)
    ("boost::tuple" [tuple] "<boost/tuple.hpp>" (:doc "Ease definition of functions returning multiple values, and more.") 'class-template)
    ("boost::tuple" [tuple] "<boost/tuple/tuple.hpp>" (:doc "A tuple (or n-tuple) is a fixed size collection of elements. Pairs, triples, quadruples etc. are tuples. These element objects may be of different types.") 'class-template)
    ("boost::unordered" [unordered] "<boost/unordered.hpp>" (:doc "Unordered associative containers.") 'class-template)
    ("boost::variant" [variant] "<boost/variant.hpp>" (:doc "Safe, generic, stack-based discriminated union container.") 'class-template)
    ("boost::optional" [optional] "<boost/optional.hpp>" (:doc "Template wrapping value types to having an additional undefined state.") 'class-template)
    ("boost::string_ref" [string_ref] "<boost/utility/string_ref.hpp>" (:doc "Non-owning string reference.") 'class-template) ;http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3442.html
    )
  "C++ Boost Basic Container templates (in `boost' namespace)."
  )

(defconst c++-boost-ublas-containers
  '(
    ("boost::numeric::ublas::vector" [numeric::ublas::vector] "<boost/numeric/ublas/vector.hpp>" (:doc "Base container adaptor for dense vectors.") 'class-template)
    ("boost::numeric::ublas::unit_vector" [numeric::ublas::unit_vector] "<boost/numeric/ublas/vector.hpp>" (:doc "Canonical unit vectors. For the k-th n-dimensional canonical unit vector and 0 <= i < n holds uki = 0, if i <> k, and uki = 1.") 'class-template)
    ("boost::numeric::ublas::zero_vector" [numeric::ublas::zero_vector] "<boost/numeric/ublas/vector.hpp>" (:doc "Zero vectors. For a n-dimensional zero vector and 0 <= i < n holds zi = 0.") 'class-template)
    ("boost::numeric::ublas::scalar_vector" [numeric::ublas::scalar_vector] "<boost/numeric/ublas/vector.hpp>" (:doc "Represents scalar vectors. For a n-dimensional scalar vector and 0 <= i < n holds zi = s.") 'class-template)
    )
  "C++ Boost UBlas Container templates (in `boost' namespace)."
  )

(defconst c++-boost-containers
  (append
   c++-boost-basic-containers
   c++-boost-ublas-containers
   )
  "C++ Boost Container templates (in `boost' namespace)."
  )

(defconst c++-boost-algorithms
  '(
    ("boost::foreach" [foreach] "<boost/foreach.hpp>" (:doc "BOOST_FOREACH macro for easily iterating over the elements of a sequence.") 'class-template)
    ("boost::gil" [gil] "<boost/gil.hpp>" (:doc "Generic Image Library.") 'class-template)
    ("boost::graph" [graph] "<boost/graph.hpp>" (:doc "Generic graph components and algorithms.") 'class-template)
    ("boost::minmax" [minmax] "<boost/minmax.hpp>" (:doc "standard library extensions for simultaneous min/max and min/max element computations.") 'class-template)
    ("boost::range" [range] "<boost/range.hpp>" (:doc "A new infrastructure for generic algorithms that builds on top of the new iterator concepts.") 'class-template)
    ("boost::string_algo" [string_algo] "<boost/string_algo.hpp>" (:doc "String algorithms library") 'class-template)
    ("boost::utility" [utility] "<boost/utility.hpp>" (:doc "Class next(),  prior() function templates.") 'class-template)
    )
  "C++ Boost Algorithms."
  )

(defconst c++-boost-smart-pointers
  '(
    ("boost::scoped_ptr" [scoped_ptr] "<boost/scoped_ptr.hpp>" (:doc "Simple sole ownership of single objects. Noncopyable.") 'class-template)
    ("boost::scoped_array" [scoped_array] "<boost/scoped_array.hpp>" (:doc "Simple sole ownership of arrays. Noncopyable.") 'class-template)
    ("boost::shared_ptr" [shared_ptr] "<boost/shared_ptr.hpp>" (:doc "Object ownership shared among multiple pointers.") 'class-template)
    ("boost::shared_array" [shared_array] "<boost/shared_array.hpp>" (:doc "Array ownership shared among multiple pointers.") 'class-template)
    ("boost::weak_ptr" [weak_ptr] "<boost/weak_ptr.hpp>" (:doc "Non-owning observers of an object owned by shared_ptr.") 'class-template)
    ("boost::intrusive_ptr" [intrusive_ptr] "<boost/intrusive_ptr.hpp>" (:doc "Shared ownership of objects with an embedded reference count.") 'class-template)
    )
  "C++ Boost Smart Pointer class templates. See
  http://www.boost.org/doc/libs/1_39_0/libs/smart_ptr/smart_ptr.htm
  for details. These templates are designed to complement the
  std::auto_ptr template.")

(defconst c++-boost-compiler-config-constants
  '(
    "BOOST_NO_RVALUE_REFERENCES"
    )
  "C++ Boost Compiler Configuration Constants. Defined in sub-directory
  boost/config/select_compiler_config.hpp.")

;; TODO: Define function that Lookup these by cpp-only compiling using a given compiler command and check the output.

(defconst c++-smart-pointers
  '(
    ("std::auto_ptr" [auto_ptr] "<memory>" (:doc "Unique ownership at single pointer. Better alternative to auto_ptr." :std c++11) 'class-template)
    )
  "C11 Smart Pointers.")

(defconst c++11-smart-pointers
  '(
    ("std::shared_ptr" [shared_ptr] "<memory>" (:doc "Object ownership shared among multiple pointers." :std c++11) 'class-template)
    ("std::unique_ptr" [unique_ptr] "<memory>" (:doc "Unique ownership at single pointer. Better alternative to auto_ptr." :std c++11) 'class-template)
    ("std::weak_ptr" [weak_ptr] "<memory>" (:doc "Non-owning observers of an object owned by shared_ptr." :std c++11) 'class-template)
    )
  "C++11 Smart Pointers. See https://secure.wikimedia.org/wikipedia/en/wiki/Smart_pointer#C.2B.2B_Smart_Pointers")
;; TODO: C++-0x moves the std::tr1::shared_ptr smart pointer to the std namespace and adds support for make_shared() and allocate_shared().
;; TODO: Support make_shared() and allocate_shared().

(defconst c++-amp-containers
  '(
    ("concurrency::..." [...] "<amp.h>" (:doc "...") 'class-template)
    )
  "Microsoft C++ AMP Containers."
  )

(defconst c++-amp-algorithm
  '(
    ("concurrency::parallel_for_each" [parallel_for_each] "<amp.h>" (:doc "Parallel variant of std::for_each.") 'class-template)
    )
  "Microsoft C++ AMP Algorithms."
  )

(defconst c++-tbb-containers
  '(
    ("tbb::concurrent_vector" [concurrent_vector] "<tbb/concurrent_vector.hpp>" (:doc "Concurrent variant of std::vector.") 'class-template)
    ("tbb::concurrent_hash_map" [concurrent_hash_map] "<tbb/concurrent_hash_map.hpp>" (:doc "Concurrent variant of std::hash_map.") 'class-template)
    ("tbb::concurrent_queue" [concurrent_queue] "<tbb/concurrent_queue.hpp>" (:doc "Concurrent variant of std::queue.") 'class-template)
    ("tbb::concurrent_unordered_set" [concurrent_unordered_set] "<tbb/concurrent_unordered_set.hpp>" (:doc "Concurrent variant of std::unordered_set.") 'class-template)
    ("tbb::concurrent_unordered_map" [concurrent_unordered_map] "<tbb/concurrent_unordered_map.hpp>" (:doc "Concurrent variant of std::unordered_map.") 'class-template)
    )
  "Intel TBB C++ Container templates (in `tbb' namespace)."
  )

(defconst c++-ppl-containers
  '(
    ("ppl::concurrent_vector" [concurrent_vector] "<ppl/concurrent_vector.hpp>" (:doc "Concurrent variant of std::vector.") 'class-template)
    ("ppl::concurrent_queue" [concurrent_queue] "<ppl/concurrent_queue.hpp>" (:doc "Concurrent variant of std::queue.") 'class-template)
    ("ppl::concurrent_unordered_multimap" [concurrent_unordered_multimap] "<ppl/concurrent_unordered_multimap.hpp>" (:doc "Concurrent variant of std::unordered_multimap.") 'class-template)
    ("ppl::concurrent_unordered_multimultimap" [concurrent_unordered_multimap] "<ppl/concurrent_unordered_multimap.hpp>" (:doc "Concurrent variant of std::unordered_multimap.") 'class-template)
    ("ppl::concurrent_unordered_set" [concurrent_unordered_set] "<ppl/concurrent_unordered_set.hpp>" (:doc "Concurrent variant of std::unordered_set.") 'class-template)
    ("ppl::concurrent_unordered_multiset" [concurrent_unordered_set] "<ppl/concurrent_unordered_set.hpp>" (:doc "Concurrent variant of std::unordered_set.") 'class-template)
    )
  "Microsoft PPL C++ Container templates (in `ppl' namespace)."
  )

(defconst c++-tbb-blocked-ranges
  '(
    ("tbb::blocked_range" [blocked_range] "<tbb/blocked_range.hpp>" (:doc "Block one-dimensional range.") 'class-template)
    ("tbb::blocked_range2d" [blocked_range2d] "<tbb/blocked_range2d.hpp>" (:doc "Block two-dimensional range.") 'class-template)
    ("tbb::blocked_range3d" [blocked_range3d] "<tbb/blocked_range3d.hpp>" (:doc "Block two-dimensional range.") 'class-template)
    )
  "Intel TBB C++ Blocked Ranges (in `tbb' namespace)."
  )

(defconst c++-tbb-algorithms
  '(
    ("tbb::parallel_do" [for] "<tbb/parallel_do.hpp>" (:doc "Parallel do loop.") 'class-template)
    ("tbb::parallel_while" [while] "<tbb/parallel_while.hpp>" (:doc "Parallel while loop.") 'class-template)
    ("tbb::parallel_for" [for] "<tbb/parallel_for.hpp>" (:doc "Parallel version of for loop.") 'class-template)
    ("tbb::parallel_for_each" [for_each] "<tbb/parallel_for_each.hpp>" (:doc "Parallel version of std::for_each.") 'class-template)
    ("tbb::parallel_reduce" [reduce] "<tbb/parallel_reduce.hpp>" (:doc "Parallel reduce.") 'class-template)
    ("tbb::parallel_invoke" [invoke] "<tbb/parallel_invoke.hpp>" (:doc "Parallel invoke.") 'class-template)
    ("tbb::parallel_scan" [scan] "<tbb/parallel_scan.hpp>" (:doc "Parallel Scan.") 'class-template)
    ("tbb::parallel_sort" [sort] "<tbb/parallel_sort.hpp>" (:doc "Parallel Sort.") 'class-template)
    )
  "Intel TBB C++ Algorithms (in `tbb' namespace)."
  )

(defconst c++-ppl-algorithms
  '(
    ("ppl::parallel_do" [for] "<ppl/parallel_do.hpp>" (:doc "Parallel do loop.") 'class-template)
    ("ppl::parallel_while" [while] "<ppl/parallel_while.hpp>" (:doc "Parallel while loop.") 'class-template)
    ("ppl::parallel_for" [for] "<ppl/parallel_for.hpp>" (:doc "Parallel version of for loop.") 'class-template)
    ("ppl::parallel_for_each" [for_each] "<ppl/parallel_for_each.hpp>" (:doc "Parallel version of std::for_each.") 'class-template)
    ("ppl::parallel_invoke" [invoke] "<ppl/parallel_invoke.hpp>" (:doc "Parallel invoke.") 'class-template)
    ("ppl::parallel_scan" [scan] "<ppl/parallel_scan.hpp>" (:doc "Parallel Scan.") 'class-template)
    ("ppl::parallel_sort" [sort] "<ppl/parallel_sort.hpp>" (:doc "Parallel Sort.") 'class-template)
    )
  "Microsoft PPL C++ Algorithms (in `ppl' namespace)."
  )

(defconst c-functions
  '(
    ("assert" [assert] "<cassert>" (:doc "C assert.") 'function-template)
    )
  "C Standard Functions."
  )

(defconst c++11-functions
  '(
    ("async" [async] "<future>" (:doc "Call function asynchronously." :std c++11) 'function-template)
    )
  "C++11 Standard Functions."
  )

(defconst c++11-classes
  '(
    ("future" [future] "<future>" (:doc "Future defined value." :std c++11) 'class-template)
    ("promise" [promise] "<promise>" (:doc "Promised returned value." :std c++11) 'class-template)
    )
  "C++11 Standard Classes."
  )

(provide 'cc-assist-defs)
