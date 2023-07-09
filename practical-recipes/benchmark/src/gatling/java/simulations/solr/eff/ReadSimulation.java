package simulations.solr.eff;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;
import java.time.Duration;

public class ReadSimulation extends Simulation {

  final String targetSolr = "http://localhost:8983";
  final String collectionName = "eff_recipe";

  final FeederBuilder<String> queryFeeder = csv("generated/eff/queries.csv").random().circular();
  final String fixedQueryParams =
      "q=*:*&fl=id,name,author,field(popularity)&sort=popularity asc,id desc";

  final HttpProtocolBuilder httpProtocol =
      http.disableWarmUp()
          .shareConnections()
          .disableCaching()
          .disableFollowRedirect()
          .baseUrl(targetSolr + "/solr/" + collectionName + "/select")
          .acceptHeader("application/json");

  final ScenarioBuilder scn =
      scenario("Sort by External File Field")
          .feed(queryFeeder)
          .exec(
              http("eff:popularity").get("?#{query}&" + fixedQueryParams).check(status().is(200))
              //                    .check(bodyString().saveAs("BODY"))
              )
      //            .exec(session -> {
      //                System.out.println(session.get("BODY").toString());
      //                return session;
      //            })
      ;

  {
    setUp(scn.injectOpen(constantUsersPerSec(10).during(Duration.ofMinutes(1))))
        .protocols(httpProtocol);
  }
}
