import { default as computed, observes, on } from 'ember-addons/ember-computed-decorators';
import { getOwner } from 'discourse-common/lib/get-owner';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend({
  filter: null,
  userList: [],
  type: 'going',

  @observes('type', 'model.topic')
  setUserList() {
    this.set('loadingList', true);

    const type = this.get('type');
    const topic = this.get('model.topic');

    ajax(`/calendar-events/rsvp/${type}`, {
      data: {
        topic_id: topic.id
      }
    }).then((userList) => {
      if (userList.length) {
        this.setProperties({
          userList,
          loadingList: false
        })
      }
    });
  },

  @computed('type')
  goingNavClass(type) {
    return type === 'going' ? 'active' : '';
  },

  @computed('userList', 'filter')
  filteredList(userList, filter) {
    if (filter) {
      userList = userList.filter((u) => u.username.indexOf(filter) > -1);
    }

    const currentUser = this.get('currentUser');
    if (currentUser) {
      userList.sort((a, b) => {
        if (a.id === currentUser.id) {
          return -1;
        } else {
          return 1;
        }
      });
    }

    return userList;
  },

  actions: {
    setType(type) {
      this.set('type', type);
    },

    composePrivateMessage(user) {
      const controller = getOwner(this).lookup('controller:application');
      this.send('closeModal');
      controller.send('composePrivateMessage', user);
    }
  }
});
