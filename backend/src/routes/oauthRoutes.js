import express from 'express';
import * as oauthController from '../controllers/oauthController.js';

// OAuth authorization server used by the MCP server. Mounted at /oauth; the metadata
// document lives at /.well-known/oauth-authorization-server (see server.js).
const router = express.Router();

router.post('/register', oauthController.register);
router.get('/authorize', oauthController.authorize);
router.post('/token', oauthController.token);
router.post('/revoke', oauthController.revoke);
router.post('/introspect', oauthController.introspect);

// Called by the MCP sign-in page (mcp-frontend).
router.get('/requests/:id', oauthController.getRequest);
router.post('/requests/:id/approve', oauthController.approveRequest);
router.post('/requests/:id/deny', oauthController.denyRequest);

export default router;
