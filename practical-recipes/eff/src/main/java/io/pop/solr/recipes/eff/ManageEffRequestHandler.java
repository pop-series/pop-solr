package io.pop.solr.recipes.eff;

import org.apache.solr.handler.RequestHandlerBase;
import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.response.SolrQueryResponse;
import org.apache.solr.security.AuthorizationContext;
import org.apache.solr.security.PermissionNameProvider;

import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.nio.channels.ReadableByteChannel;
import java.util.Map;

public class ManageEffRequestHandler extends RequestHandlerBase {
    public static final String FIELD_QUERY_PARAM = "fieldName";
    public static final String SOURCE_FILE_NAME = "sourceFileName";
    public static final String TARGET_FILE_NAME = "targetFileName";

    @Override
    public void handleRequestBody(SolrQueryRequest req, SolrQueryResponse rsp) throws Exception {
        final String fieldName = req.getParams().get(FIELD_QUERY_PARAM);
        final String sourceFileName = req.getParams().get(SOURCE_FILE_NAME);
        final String targetFileName = req.getParams().get(TARGET_FILE_NAME);

        if (!req.getSchema().hasExplicitField(fieldName)) {
            throw new NoSuchFieldException(fieldName);
        }

        final String targetFilePath = req.getCore().getDataDir() + "/" + targetFileName;
        doInternal(sourceFileName, targetFilePath);
        rsp.add("sourceFileName", sourceFileName);
        rsp.add("targetFileName", targetFileName);
        rsp.add("targetFilePath", targetFilePath);
        rsp.addResponse("done");
    }

    void doInternal(final String sourceFileName, String targetFilePath) throws IOException {
        final String downloadLocation = invariants.get("downloadLocation");
        final URL url = new URL(downloadLocation + "/" + sourceFileName);
        try (final ReadableByteChannel readableByteChannel = Channels.newChannel(url.openStream())) {
            try (final FileOutputStream fileOutputStream = new FileOutputStream(targetFilePath)) {
                try (final FileChannel fileChannel = fileOutputStream.getChannel()) {
                    fileChannel.transferFrom(readableByteChannel, 0, Long.MAX_VALUE);
                }
            }
        }
    }

    @Override
    public String getDescription() {
        return getClass().getSimpleName();
    }

    @Override
    public PermissionNameProvider.Name getPermissionName(AuthorizationContext request) {
        return PermissionNameProvider.Name.COLL_EDIT_PERM;
    }
}
