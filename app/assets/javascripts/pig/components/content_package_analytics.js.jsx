var ContentPackageAnalytics = React.createClass({
  getInitialState: function() {
   return {
     isLoading: true,
     pageViewCount: ''
   };
 },
 componentDidMount: function() {
    $.get(this.props.analyticsPath, function(result) {
      if (this.isMounted()) {
        this.setState({
          isLoading: false,
          pageViewsCount: result.total,
          referrers: result.referrers
        });
      }
    }.bind(this)).fail(function(result) {
      this.setState({
        isLoading: false,
        error: result.responseJSON.error
      });
    }.bind(this));
  },
  render: function() {
    if (this.state.isLoading) {
      content = (
        <div className={this.state.isLoading ? '' : 'hide'}>
          <i className="fa fa-circle-o-notch fa-spin fa-2x"></i>
        </div>
      );
    }
    else if (this.state.error) {
      content = (
        <h3>
        {this.state.error}
        </h3>
      );
    }
    else {
      content = (
        <div>
          <label className="col-primary">Total page views</label>
          <p>{this.state.pageViewsCount}</p>
          <label className="col-primary">Referrers</label>
          <AnalyticReferrers data={this.state.referrers} />
        </div>
      );
    }
    return (
      <div>
        {content}
      </div>
    );
  }
});

var AnalyticReferrers = React.createClass({
  render: function() {
    var referrerNodes = this.props.data.map(function (referrer) {
      return (
        <li>
          <span>{referrer.name} - {referrer.total}</span>
          <AnalyticReferrerKeyword data={referrer.keywords} />
        </li>
      );
    });
    return (
      <ul className="list-unstyled">
        {referrerNodes}
      </ul>
    );
  }
});

var AnalyticReferrerKeyword = React.createClass({
  render: function() {
    var keywordNodes = this.props.data.map(function (keyword) {
      return (
        <li>
          <span>{keyword.word} - {keyword.total}</span>
        </li>
      );
    });
    return (
      <ul>{keywordNodes}</ul>
    );
  }
});
