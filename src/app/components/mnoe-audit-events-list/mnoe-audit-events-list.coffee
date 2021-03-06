#
# Mnoe Audit Events list
#
@App.component('mnoeAuditEventsList', {
  templateUrl: 'app/components/mnoe-audit-events-list/mnoe-audit-events-list.html',
  bindings: {}
  controller: ($log, MnoeAuditEvents) ->
    vm = this

    vm.events =
      search: {}
      sort: "created_at.desc"
      nbItems: 20
      offset: 0
      page: 1
      list: []
      pageChangedCb: (nbItems, page) ->
        vm.events.nbItems = nbItems
        vm.events.page = page
        vm.events.offset = (page  - 1) * nbItems
        fetchEvents(nbItems, vm.events.offset)

    # Manage sorting, search and pagination
    vm.callServer = (tableState) ->
      vm.events.sort = updateSort(tableState.sort)
      fetchEvents(vm.events.nbItems, vm.events.offset, vm.events.sort)

    # Update sorting parameters
    updateSort = (sortState = {}) ->
      sort = "created_at.desc"
      if sortState.predicate
        sort = sortState.predicate
        if sortState.reverse
          sort += ".desc"
        else
          sort += ".asc"

      return sort

    # Fetch events
    fetchEvents = (limit, offset, sort = vm.events.sort) ->
      vm.events.loading = true
      # TODO: search
      return MnoeAuditEvents.list(limit, offset, sort).then(
        (response) ->
          vm.events.totalItems = response.headers('x-total-count')
          vm.events.list = response.data
      ).finally(-> vm.events.loading = false)

    return
})
