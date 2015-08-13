var PackageReassigner = React.createClass({
  getInitialState: function() {
    return {content: []};
  },
  show: function() {
    component = this;
    $.get(this.props.contentUrl, function(data) {
      modal = $('#package-reassigner-modal-user-' + component.props.userId);
      modal.modal('show');
      component.setState({content: data});
    });
  },
  render: function() {
    var contentRows = [];
    var component = this;
    this.state.content.forEach(function(content) {
      contentRows.push(<ReassignableContent {...content} users={component.props.users} key={content.id}/>);
    });
    var optionRows = [];
    JSON.parse(this.props.users).forEach(function(user) {
      optionRows.push(<option value={user.id} key={user.id}>{user.full_name}</option>);
    });
    return <div className="modal fade" id={"package-reassigner-modal-user-" + this.props.userId}>
      <div className="modal-dialog">
        <form action={this.props.deactivateUrl} method="POST">
          <div className="modal-content">
            <div className="modal-header">
              <button className="close-btn" type="button" data-dismiss="modal">
                <i className="fa.fa-times" />
              </button>
              <h4 className="modal-title">Reassign Content</h4>
            </div>
            <div className="modal-body">
              <p>
                {this.state.content.length == 0 ? 'This user has no content currently assigned to them.' : 'Please choose who you would like to reassign this user\'s content to:'}
              </p>
              <If test={this.state.content.length > 0}>
                <table className="table select-table table-full-width">
                  <tr>
                    <td>
                      Resassign all content to
                    </td>
                    <td>
                      <select name="all_content_package" className="input-sm pull-right" onChange={this.updateAllReassignableContent}>
                        {optionRows}
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td colSpan="2" className="align-center table-spacer">
                      or assign content individually
                    </td>
                  </tr>
                  {contentRows}
                </table>
              </If>
            </div>
            <div className="modal-footer">
              <a className="btn btn-default" data-dismiss="modal">
                Cancel
              </a>
              <input className="btn btn-error" type="submit" value={"Deactivate user" + (this.state.content.length > 0 ? ' and reassign content' : '')} />
            </div>
          </div>
        </form>
      </div>
      </div>;
  },
  updateAllReassignableContent: function() {
    $('.deactivate-user-select').val($(event.target).val());
  }
});
