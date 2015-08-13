var ReassignableContent = React.createClass({
  render: function() {
    var optionRows = [];
    var component = this;
    JSON.parse(this.props.users).forEach(function(user) {
      optionRows.push(<option value={user.id} key={user.id}>{user.full_name}</option>);
    });
    return <tr>
        <td>
          {this.props.name}
        </td>
        <td>
          <select name={"content_package[" + this.props.id + "]"} className="input-sm deactivate-user-select pull-right">
            {optionRows}
          </select>
        </td>
      </tr>;
  }
});
