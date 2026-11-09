import sys

p = r'C:\Users\thuyn\.copilot\repos\gimbal-dashboard-tn\public\web\index.html'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

target = '    function toggleGoogleAuthModal(open) {'

new_oauth_code = '''    // ==========================================================================
    // AUTHENTIC GOOGLE OAUTH POPUP FLOW
    // ==========================================================================
    function loginWithGoogleOAuth() {
      const width = 480;
      const height = 640;
      const left = window.screenX + (window.outerWidth - width) / 2;
      const top = window.screenY + (window.outerHeight - height) / 2;

      try {
        const popup = window.open(
          'google_auth.html',
          'GoogleAccountsOAuth',
          `width=${width},height=${height},left=${left},top=${top},status=no,resizable=yes,scrollbars=yes`
        );

        if (!popup || popup.closed || typeof popup.closed === 'undefined') {
          // If popup is blocked by browser, redirect smoothly
          window.location.href = 'google_auth.html';
        } else if (popup && popup.focus) {
          popup.focus();
        }
      } catch (e) {
        window.location.href = 'google_auth.html';
      }
    }

    // Listen for Google OAuth success message from authentic google_auth.html popup
    window.addEventListener('message', function(event) {
      if (event.data && event.data.type === 'GOOGLE_OAUTH_SUCCESS') {
        const googleUser = event.data.user;
        if (googleUser && googleUser.email && typeof SmartGimbalCatalog !== 'undefined') {
          SmartGimbalCatalog.loginWithGmail(googleUser.email, googleUser.name);
          toggleAuthModal(false);
          renderNavUserSection();
          renderReviewsList();
          showToast('✓ Đăng nhập Google thành công (' + googleUser.email + ')');
        }
      }
    });

    // Check if user just redirected back from google_auth.html
    try {
      const redirectedUserStr = localStorage.getItem('tflow_google_auth_redirect_user');
      if (redirectedUserStr) {
        localStorage.removeItem('tflow_google_auth_redirect_user');
        const rUser = JSON.parse(redirectedUserStr);
        if (rUser && rUser.email && typeof SmartGimbalCatalog !== 'undefined') {
          SmartGimbalCatalog.loginWithGmail(rUser.email, rUser.name);
          renderNavUserSection();
          renderReviewsList();
          showToast('✓ Đăng nhập Google thành công (' + rUser.email + ')');
        }
      }
    } catch(err) {}

    function toggleGoogleAuthModal(open) {'''

if target in text:
    text = text.replace(target, new_oauth_code, 1)
    print('Inserted loginWithGoogleOAuth and listener successfully!')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(text)
else:
    print('Target not matched!')
