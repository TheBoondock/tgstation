import { Section, Button, Box, Table } from '../components';
import { NtosWindow } from '../layouts';

export const SocialRating = (prop, context) => {
  return (
    <NtosWindow width={600} height={500}>
      <NtosWindow.Content scrollable>
        <Section
          title="Something"
          button={<Button icon="anything" content="anything" />}>
          <Box> This is a crewmate rating app </Box>
          <Table>
            <Table.Row>
              <Table.Cell bold>Hello world!</Table.Cell>
              <Table.Cell collapsing color="label">
                Label
              </Table.Cell>
            </Table.Row>
          </Table>
        </Section>
        <Section title="Subheader">
          This is the bodytext of this section
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
